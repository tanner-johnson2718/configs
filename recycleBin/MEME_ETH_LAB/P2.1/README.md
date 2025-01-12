# Using Sysfs to play with RPI Eth Devices

## Sysfs entry of `/sys/class/net/eth0` (Interface)

* used `/sys/class/net/eth0` to find NIC sysfs entry
* If we list this dir we can see several interesting interfaces and information that the NIC exports:
    * https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-class-net

| Entry | Value | Desc |
| --- | --- | --- |
| addr_assign_type | 0 | Indicates the address assignment type. 0 =  permanant address. 1 = randomly generated. 2 = stolen from another device. 3 = set using dev_set_mac_addr |
| addr_len | 6 | Physical layer address len |
| address | d8:3a:dd:49:fc:c2 | Physical Layer addr |
| broadcast | ff:ff:ff:ff:ff:ff | Physical Layer broadcast address |
| carrier | 0 | Physical Link state. 0 down, 1 up |
| carrier_changes, carrier_up, carrier_down | 0,0,0 | Stats on physical link state changes |
| dev_id | 0x0 | ?? |
| dev_port | 0 | ?? |
| device | -> ../../../fd580000.ethernet | ?? |
| dormant | 0 | 1 = in dormant state 0 = not. |
| duplex | unknown | Full or half duplex. Is unknown cause could negotiate to either when link is up |
| flags | 0x1003 | [include/uapi/linux/if.h](../buildroot/output/build/linux-custom/include/uapi/linux/if.h) |
| gro_flush_timeout | 0 | ?? |
| ifalias | "" | interface alias if it has one |
| ifindex | 2 | index to identify interface | 
| iflink | 2 | ?? |
| link_mode | 0 | Used in conjunction with dormant. 0 = default. 1 = dormant link mode |
| mtu | 1500 | max transfer unit |
| name_assign_type | ?? | ?? |
| napi_defer_hard_irqs | 0 | indicates the number of queue scan attempts before exiting to interrupt context |
| netdev_group | 0 | Which net group does it belong too |
| operstate | down | RFC2863 operational state |
| phydev | -> ../../unimac-mdio.-19/mdio_bus/unimac-mdio--1 | ?? | 
| phys_port_id, phys_port_name, phys_switch_id | cant read | ?? |
| power | ?? | ?? |
| proto_down | 0 | indicates protocol error |
| queues | Has sub dirs rw-0, tx-0 through tx-3. Each queue has some stats, settings, and state associated with it | - |
| speed | -1 | link speed in Mbits/sec |
| statistics | lots o stats | lots o stats |
| subsystem | link to subsystem containing this if | - |
| testing | 0 | assuming this identifies if it is in a testing state |
| tx_queue_len | 1000 | INTERFACE tx queue len in num packets. Assuming this is different than the tx queues of the NIC | 
| type | 1 | protocol type. [include/uapi/linux/if_arp.h](../buildroot/output/build/linux-custom/include/uapi/linux/if_arp.h) |
| uevent | INTERFACE=eth0 IFINDEX=2 | ?? |

## Sysfs for Finding PHY and MAC Info

```bash
# Find the find phydriver. We use the sysfs interface to find the net interface
# which has symlinks to the PHY and MAC sysfs entries which we look at below.
cd /sys/class/net/eth0
cd phydev
ls -la 
cat phy_id
cd ..
cd driver
ls -la
```

```
# ls -la
total 0
drwxr-xr-x    4 root     root             0 Jan  1 01:39 .
drwxr-xr-x    5 root     root             0 Jan  1 01:39 ..
lrwxrwxrwx    1 root     root             0 Jan  1 01:39 attached_dev -> ../../../../net/eth0
lrwxrwxrwx    1 root     root             0 Jan  1 01:39 driver -> ../../../../../../../../bus/mdio_bus/drivers/Broadcom BCM54213PE
lrwxrwxrwx    1 root     root             0 Jan  1 01:39 of_node -> ../../../../../../../../firmware/devicetree/base/scb/ethernet@7d580000/mdio@e14/ethernet-phy@1
-r--r--r--    1 root     root          4096 Jan  1 01:39 phy_has_fixups
-r--r--r--    1 root     root          4096 Jan  1 01:39 phy_id
-r--r--r--    1 root     root          4096 Jan  1 01:39 phy_interface
drwxr-xr-x    2 root     root             0 Jan  1 01:39 power
drwxr-xr-x    2 root     root             0 Jan  1 01:39 statistics
lrwxrwxrwx    1 root     root             0 Jan  1 01:39 subsystem -> ../../../../../../../../bus/mdio_bus
-rw-r--r--    1 root     root          4096 Jan  1 01:39 uevent
# cat phy_id
0x600d84a2
```

* The pi phy is BCM54213PE
* The of_node symlink points to the entry in the device tree
* Have a symlink for the network device interface eth0
* scb = serial control bus
* `cd .../linux-custom/drivers` then `grep -Rnw ./* -e 'BCM54213PE'` gives us the PHY driver code: /net/phy/broadcom.c
* The stats dir gives per PHY statistics (bytes read, written, errors).

```
#  ls -la
total 0
drwxr-xr-x    5 root     root             0 Jan  1 00:00 .
drwxr-xr-x   10 root     root             0 Jan  1 00:00 ..
lrwxrwxrwx    1 root     root             0 Jan  1 01:46 driver -> ../../../../bus/platform/drivers/bcmgenet
-rw-r--r--    1 root     root          4096 Jan  1 01:46 driver_override
-r--r--r--    1 root     root          4096 Jan  1 01:46 modalias
drwxr-xr-x    3 root     root             0 Jan  1 00:00 net
lrwxrwxrwx    1 root     root             0 Jan  1 01:46 of_node -> ../../../../firmware/devicetree/base/scb/ethernet@7d580000
drwxr-xr-x    2 root     root             0 Jan  1 01:46 power
lrwxrwxrwx    1 root     root             0 Jan  1 01:46 subsystem -> ../../../../bus/platform
-rw-r--r--    1 root     root          4096 Jan  1 01:46 uevent
drwxr-xr-x    4 root     root             0 Jan  1 01:39 unimac-mdio.-19

```

* Pi MAC is bcmgenet (its bus is the platfrom which implies the MAC is integrated into the BCM2711)
* Driver is located at `drivers/net/ethernet/broadcom/genet/bcmgenet.`


# Sysfs Appendix

The past few MEME projects made heavy use of the sysfs interface. The goal here is to use the above playing around with sysfs to generate target questions that show how sysfs works,  how to use it, how its organized, etc. The first thing we notice when we `cd /sys` is we the top dir layout of the interface.

```bash
dr-xr-xr-x   12 root     root             0 Jan  1 00:00 .
drwxr-xr-x   18 root     root          1024 Nov 10  2023 ..
drwxr-xr-x    2 root     root             0 Jan  1 00:00 block
drwxr-xr-x   27 root     root             0 Jan  1 00:00 bus
drwxr-xr-x   54 root     root             0 Jan  1 00:00 class
drwxr-xr-x    4 root     root             0 Jan  1 00:00 dev
drwxr-xr-x   10 root     root             0 Jan  1 00:00 devices
drwxr-xr-x    3 root     root             0 Jan  1 00:00 firmware
drwxr-xr-x    7 root     root             0 Jan  1 00:00 fs
drwxr-xr-x   12 root     root             0 Jan  1 00:00 kernel
drwxr-xr-x   70 root     root             0 Jan  1 00:00 module
drwxr-xr-x    2 root     root             0 Jan  1 00:00 power
```

## `/sys/class`

This dir appears to enumerate all the devices registered to the kernel based on its "class" of the device. `tree -L 2 /sys/class` gives a pretty good graphical representation of all devices. Here is a small snippit from the output of this command on the rpi:

```
/sys/class

...

|-- net
|   |-- eth0 -> ../../devices/platform/scb/fd580000.ethernet/net/eth0
|   `-- lo -> ../../devices/virtual/net/lo

...

```

Devices for interfaces like such as i2c, spi, hdmi, dma, ram, etc can all be found here and enumerated using the `/sys/class` dir interface.

A question that comes up from looking at this is how does a driver register its class and export its sysfs device location to this dir. This process is covered rather neatly by [this](https://docs.kernel.org/driver-api/driver-model/binding.html).

## `/sys/bus`

Another interesting look at the sysfs interface is through the bus dir. It enumerates every bus on the system and each bus contains a driver's and device's dir containing syminks to the respective driver and device sysfs entry. [This](https://www.kernel.org/doc/html/latest/driver-api/driver-model/bus.html) kernel doc entry describes this layout. This dir provides a flat layout of the device tree, grouping by bus and this is another good candiate to run the `tree` command on to get an idea of all the devices on a system. Finally we can also draw the conclusion that the `/sys/devices` dir is the "main" dir. All links to devices point into this dir.

## `/sys/fs`

This subdir is rather straight forward. For each kernel supported fs, there is a dir in `/sys/fs`. In each fs type there are sub dirs for the partitions containting file systems of that type, which in turn contain some stats on the files system that dir represents.

## `/sys/module`

Contains a dir for every module loaded on the system. Each module has a parameters dir with a list a parameters one can change. For example "kgdboc" (Kernel GDB over console) has a single parametere `/sys/module/kgdboc/parameters/kgdboc` which contains the serial console that facilitates kgdboc.

## `/sys/firmware`

Contains a binary form of the device tree and file heiarchy containing its expanded contents

## `/sys/power`

Unclear

## `/sys/block`

Links into the devices dir for all the block devices.

## `/sys/dev`

Links into the devices dir for all the block and char devices.

## `/sys/devices` 

The devices dir is a filesystem representation of the device treemodule/ contains parameter values and state information for all loaded system modules, for both builtin and loadable modules.

## `/sys/kernel`

The kernel dir really only contains two interesting subdirs:

### [irq](https://www.kernel.org/doc/html/v4.18/core-api/genericirq.html)
| IRQ Entry | Value | Comments | 
| --- | --- | --- |
| actions | IRI | - |
| chipname | GICv2 | ARM Generic Interrupt Controller | 
| hwirq | 0 | HW IRQ number |
| name | "" | - |
| per_cpu_count | 69,420,312,123 | Per CPU num times this irq has been raised | 
| type | Edge | trigger type
| wakeup | disabled | Boot up PC? |

### slab

Kernel memory slabs listing?

# Resources

* https://www.kernel.org/doc/html/latest/driver-api/driver-model/
    * https://docs.kernel.org/driver-api/driver-model/binding.html
    * https://www.kernel.org/doc/html/latest/driver-api/driver-model/bus.html
* https://www.kernel.org/doc/html/next/filesystems/sysfs.html
* https://www.kernel.org/doc/html/v4.18/core-api/genericirq.html