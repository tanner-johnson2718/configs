# Reverse Engineering the BCM54213PE Driver

* BCM54213PE driver loc -> linux-*/drivers/net/phy/broadcom.c
* installed phytool and ethtool from buildroot packages menu
* `include/linux/brcmphy.h` contains the register definitions for the PHY
* `include/linux/phy.h` contains includes for phy_read, phy state mahcine, etc.
* `drivers/net/phy/phy_device.c` contains generic phy driver device code

# Code Set Up

## Refactor Code

The first thing we want todo is refacor the code. Also we need a dedicated place for this code to reside. So we moved the official files into the `external_packages/ethraw` directory and depricated the first version contained in `P1.1`. Next we did the following:

* Created library `libEth` with common code
* Removed as much global state as possible
* Turned consts into #define's
* Added the packet generation params as input args
* Removed CRC display code and any mention of CRC
* Removed options to dump whole packet as this isn't required.

Finally, with the scripts developed in part 1, we can cross compile and send the newly factored code to the PI with the following (making sure it is powered on and logged into):

```bash
source ./scripts/env_init.sh
./scripts/rebuild_external_package.sh ethraw
./scripts/serial_push ./buildroot/output/build/ethraw*/gen
./scripts/serial_push ./buildroot/output/build/ethraw*/sniff
```

And on the host side we can build x86 versions of the code:

```bash
cd external_packages/ethraw/src
make
```

## CRC, Packet Len, and MAC addr Lessons

We set up the laptop to send and the pi to recv and noticed the following:

* Packets inbound to pi must have MAC dest match or have a broadcast MAC to register
* In C code, raw sockets do not have any transparency into CRC, it is purely hardware.
    * Although 802.3 states this can be done by the MAC or PHY
* Stats on interface can be dumped via the [script](../scripts/sysfs_net_stat_dump.sh)
* If not listening for raw socket packets they get dropped
* Max Packet len is 1518 including CRC and 1514 in userspace raw socket

# MDIO Bus Hacking
MDIO Registers (Clause 22) | Control Reg (0x0) Bit Map 
:------------:|:------------:
![](../Docs/mdio_c22_reg_table.png) | ![](../Docs/mdio_c22_control_reg.png)

* Pull PHYID from MDIO Bus:
```bash
# phytool <read/write> <if/phy num/reg> where phy num can be pulled from the ethtool util
~ phytool read eth0/1/2
0x600d
~ phytool read eth0/1/3
0x84a2
```

* Place into loopback mode
```bash
# The default ctl reg is 0x1140. We want to wipe aneg and enable loopback so we write 0x4140
# Failure to turn off aneg breaks the interface.
phytool write eth0/1/0 0x4140
sniff eth0 &
gen eth0 d8:3a:dd:49:fc:c2 d8:3a:dd:49:fc:c2 0x6969 1000
```

* Force a PHY Reset
```bash
phytool write eth0/1/0 0x8000
```

* Force to not use aneg and manually set speed
```bash
# On both stations set the isolate and powerdown bits to disable and block the aneg proc
PC1 > phytool write <if>/<phy_ad>/0 0x0c00
PC2 > phytool write <if>/<phy_ad>/0 0x0c00

# Bring both PHYs up in the desired speed and duplex. Below shows 10Mb - Full operation
PC1 > phytool write <if>/<phy_ad>/0 0x0100
PC2 > phytool write <if>/<phy_ad>/0 0x0100
```

* Get PHY status and capabilities

MDIO Status Register (0x1) | Extended Status Register (0xf) 
:------------:|:------------:
![](../Docs/mdio_c22_status_reg.png) | ![](../Docs/mdio_c22_ext_stat_reg.png)

```bash
# Gives a Pretty output of the control and status registers
phytool print eth0/1
ieee-phy: id:0x600d84a2

   ieee-phy: reg:BMCR(0x00) val:0x1140
      flags:          -reset -loopback +aneg-enable -power-down -isolate -aneg-restart -collision-test
      speed:          1000-full

   ieee-phy: reg:BMSR(0x01) val:0x796d
      capabilities:   -100-b4 +100-f +100-h +10-f +10-h -100-t2-f -100-t2-h
      flags:          +ext-status +aneg-complete -remote-fault +aneg-capable +link -jabber +ext-register

# Supports 1000 Base T w/ both full and half duplex
phytool print eth0/1/15
ieee-phy: reg:0x0f val:0x3000
```

* PSE registers 11 and 12. PoE registers
* MMD registers 13 and 14 are used in Clause 45 addressing to expand the amount of registers on can access.
* Aneg registers, 4, 5, 6, 7, and 8 and  Master-Slave registers 9 and 10 outside of scope but are used for aneg for 1000 Base T capable PHYs


# Setting up the debug environment

Add the following to `cmdline.txt`: `kgdboc=ttyAMA0 kgdbwait`. This will halt the kernel loading as early as possible and have it wait for the debugger to connect. With this set up we will NOT use the remote gdb debugger as it is a pain in the butt and it seems as kdb (the built in command line debugger) provides a much simpler and less feature rich interface but is sufficiently powerful. To use kdb one must verify the following kernel config options are set:

```
CONFIG_FRAME_POINTER=y
CONFIG_KGDB=y
CONFIG_KGDB_SERIAL_CONSOLE=y
CONFIG_KGDB_KDB=y
CONFIG_KDB_KEYBOARD=y
CONFIG_MAGIC_SYSRQ=y
CONFIG_KALLSYMS=y
```

Booting the PI with these cmd line options and the proper config params leads to a proper early boot and then a halt with the following kdb prompt: `[0] kdb> `. This is the kdb shell interface. Typing help shows how to apply break points, get back traces, examine memory, etc. Typing go starts execution again. During execution to trigger kdb type `echo g > /proc/sysrq-trigger` which will halt the kernel and invokes kdb. Finally to completely disable kdb, type `echo '' > /sys/module/kgdboc/parameters/kgdboc`. 

## Writing KDB Modules, a case study

One benefit of kdb is we can easily extend it with kernel modules. `kernel/trace/trace_kdb.c` gives an example of a well modularized kdb module. We will use `samples/kdb/kdb_hello.c` and move it to our external packages dir, `extrern_packages/kdbhelper/`, to be build by build root. The flow we will use for this is as follows. After the first build of the system with `./scripts/build.sh`, we will rebuild any changes to our kdb modules via the `rebuild_external_packages.sh` script. On the pi run the following:

```bash
# unload current module, make sure we are at home dir, remove module from device
rmmod kdbhelper
cd ~
rm -rf kdbhelper.ko
<exit to build pc>

# Push script and load
./scripts/serial_push.sh ./buildroot/output/kdbhelper*/kdbhelper.ko
minicom
insmod kdbhelper.ko

# Enter kdb context via echo g > /proc/sysrq-trigger. Just saved into script
./kdb.sh

# When done or need to update module, clear bps and go the kernel
bc *
go
```

This flow allows one to build the `kdbhelper` module, flash it, and load it back into the kernel. The first addition we would like ot make to kdb is a way to map a kernel symbol to an address. Since we compiled with the `CONFIG_KALLSYMS=y` option we have access to the /proc/kallsyms. Which can be searched (or reverese searched) via command line tools. Core kernel KDB functions like  `kernel/debug/kdb/kdb_bp.c` and `kernel/debug/kdb/kdb_support.c` can use functions from `include/linux/kallsyms.h` but a recent kernel update removed the exporting of these kall symbols to kernel modules. This we come up with a bit of a hack using kprobes. This can be found in the current kdbhelper. One thing to keep in mind when building these kdb modules is that **kdb runs in an interupt context**, so be careful what you do in them.

## Getting KDB Instruction Dissasm

# Digging into the actual driver

The conclusion of digging into the driver is that there isn't a whole lot of interesting code here. The MAC driver more than likely is responsible for much of the much more interesting network behavior. However we share below some of our findings about the PHY driver below.

## Vendor Registers


* We will start with looking at the vendor specific registers which are defined in `include/linux/brcmphy.h`.

| Reg Addr | Name | 
| --- | --- |
| 16 | Extended control register |
| 17 | Extended status register |
| 21 | Expansion register data | 
| 23 | Expansion register select |  
| 24 | Auxiliary control register |
| 26 | Interrupt status register | 
| 27 | Interrupt mask register |
| 28 | Shadow register |

## Driver functions
 
* genphy code
    * genphy_update_link()  polled
    * genphy_read_status() polled
    * genphy_read_lpa() called on reset
    * The following commonly used ones appeared to not be called
        * genphy_aneg_done
        * genphy_read_status_fixed
        * genphy_config_eee_advert
        * genphy_setup_forced
        * genphy_restart_aneg
        * genphy_suspend
        * genphy_resume
        * genphy_loopback
        * genphy_read_abilities
        * genphy_soft_reset
* config_init and config ack is called over and over again on a PHY reset
    * proper init probably requires some timing and so stopping exe causes init to fail 
    * this causes init code to be called over and over
    * need to dig into MAC driver to verify this
* cant get ack_intr to trigger
    * IRQ for this PHY is disabled

## Messing with the LEDs

Using `brcmphy.h` for the LED codes:

```bash
# Write to select the LED expansion register
phytool write eth0/1/23 0x0f04

# Blink both lights off and on
phytool write eth0/1/21 0x0144
sleep 1
phytool write eth0/1/21 0x0155
sleep 1
....

# One on other off
phytool write eth0/1/21 0x0145
phytool write eth0/1/21 0x0154
```

see the aformentioned header file for all possible LED blink conditions.

# Resources
* [Chap 22.2 of 802.3](../Docs/document.pdf)
* https://docs.kernel.org/dev-tools/kgdb.html
* https://www.kernel.org/doc/html/next/networking/phy.html
* https://docs.kernel.org/trace/kprobes.html
