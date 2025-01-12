# Reverse Engineer Example

In this write up we will use our rpi4 jtag debugger to reverse engineer an image on an esp 32. Set up the pi and the esp32 as shown [here](./Init_PI_JTAG_Test.md). Now the rules of the game allow the following:

* We know the stage 1 boot loader boots the second stage boot loader at phy addr 0x1000
* We cannot use the source code debugger but we can use an assembly level debugger
* Goal is to extract the full binary image that is used and determine the segments loaded to memory
* Assume we have access to the [TRM](../Docs/esp32_technical_reference_manual_en.pdf)

# Step 1 Setting up the debug env

* Playing with the base openOCD installation that we have has shown that the base openOCD is not sufficient to mess with the flash memory at least using the telnet interface.
* Using the gdb `dump binary memory result.bin <start_addr> <finish_addr>` results in failed reads.
* Given this we install the esp32 openocd fork at [link](https://github.com/espressif/openocd-esp32) on the rpi

# Step 2 Writing Flash memory

* `openocd -f ./openocd_config/rpi4_interface.cfg -f target/esp32.cfg -c "adapter speed 1000" -c "bindto 192.168." -c "program_esp ../hello_world.bin 0x10000 verify exit"`

# Step 3 Pulling flash memory

* For some reason you have to use the `read_memory` command to init the spi flash
* Now can use the `dump_image <file> <addr> <count>` telnet command
* with `addr = 0x3F400000 count=0x30000` pulls the start of the binary image but only gathers the first 0x10000 bytes then fails.
    * Doing a read memory on the next chunk, `0x3f410000` fails?
    * Something is happening here maybe with regards to paging?

# Step 4 Putting a trigger on very early boot

* Pretty trivial, just use tcl commands: `halt` folled by `reset`
* Sometime messes up
* If it works seems the earliest execution we get is at `0x40000400`