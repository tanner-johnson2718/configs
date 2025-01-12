# Using a PI to Target a PI

Use the host or interface as set up [here](./Init_PI_JTAG_Test.md). Using the table below attach the following leads from the interface as described previously to the target pi as described below.

| Target PI Header PIN | BCM2835 GPIO # | JTAG Func | Color |
| --- | --- | --- | --- |
| 22 | GPIO 25 |  TCK | ORNG |
| 13 | GPIO 27 |  TMS | BRWN |
| 37 | GPIO 26 |  TDI | YLLW |
| 18 | GPIO 24 |  TDO | GREN |
| 20 |   GND   |  GND | BLCK |

```
# In config.txt in boot parition on target pi enter:
gpio=22-27=np
enable_jtag_gpio=1
```

* [SMP in openocd](https://openocd.org/doc/html/GDB-and-OpenOCD.html#usingopenocdsmpwithgdb)
* [6.3.4 more about SMP in openOCD](https://openocd.org/doc/html/Config-File-Guidelines.html)W
* [GDB openocd set up doc](https://openocd.org/doc/html/Server-Configuration.html)
* Consolodated all the rpi4 interface into one [file](./openocd_config/rpi4_interface.cfg)
* Just made our own config: [bcm2711_target.cfg](./openocd_config/bcm2711_target.cfg). Some lessons learned:
    * Need to run `$_TARGETNAME configure -rtos hwthread` for every target i.e. CPU.
    * Also need to add `-coreid $_core` to thread creation.
    * All of this is reflected in the bcm2711 config target file and creates a gdb target that behaves as expected.
* To run: 
    * ssh into pi and clone this repo
    * `cd PI_JTAG_DBGR`
    * `bcm2711_openocd.sh <IP>`
    * Open new term on host and run a cross-compiled aarch debugger loading the debug symbols
        * In [MEME ETH LAB](https://github.com/tanner-johnson2718/MEME_ETH_LAB) we use the following with our env sourced: `$AARCH_GDB -iex "${LX_FLAG_GDB}" $KERNEL_DEBUG_IMG -x $BASE_DIR/scripts/gdb_cmds_jtag.txt`
        * For more on the MEME ETH LAB env see [here](https://github.com/tanner-johnson2718/MEME_ETH_LAB/tree/master/P1.2) and [here](https://github.com/tanner-johnson2718/MEME_ETH_LAB/blob/master/P2.3/gdb_revisited.md).
        * Once aarch-gdb is loaded with debug symbols run `target extended-remote <ip>:3333` 