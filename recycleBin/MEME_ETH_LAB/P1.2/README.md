# P1.2 RPI Image

The goal of this step is to use BuildRoot to compile and flash a micro SD with a kernel we built. This will allow us to change kernel source and to compile kernel modules. We will use our [MEME OS 1](https://github.com/tanner-johnson2718/MEME_OS) as a starting point as we have some useful scripts to facilitate the dev process.

# Kernel Build ENV set up

The following was executed at the root dir and will create dir called 'buildroot' that contains the ENV for building our RPI root image.

```bash
# Download and set up repo for build root
touch .gitignore
echo 'buildroot' > .gitignore
wget https://buildroot.org/downloads/buildroot-2023.02.6.tar.xz
tar xf buildroot-2023.02.6.tar.xz
mv buildroot-2023.02.6 buildroot
rm -rf buildroot-2023.02.6.tar.xz

# Move to buildroot and build the basic buildroot config
cd buildroot
make list-defconfigs   # verify that 1 it works and 2 you see raspberrypi4_64_defconfig
make raspberrypi4_64_defconfig

# There is now a .config file containing the build params for buildroot targeting
# a 64bit RPI 4. This can be saved off and modified later. Now build the image
make
```

# RPI Init Set UP

```bash
# Move to Directory where the output image, sdcard.img resides
cd output/images

# Plug the micro sd into the build PC. Use one of the following to get the device name
lsblk
dmesg

# This will give you the device name, partition name, and the mound location. Umount the partition and the mount location
sudo umount /media/user/3158-99
sudo umount /dev/mmcblk0p0

# Flash the image to the SD card
sudo dd if=sdcard.img of=/dev/mmcblk0

# Put the micro sd into the PI and connct the GND (6), UART TX (8), and UART RX (10) pins on the rpi to the UART to USB adapter. Plug USB adapter into build PC. Run the following to see the dev name
dmesg

# Plug in RPI power supply and then connect to rpi
minicom -D /dev/ttyUSB0 -b 115200

# Once in mini com CTL A is the escape key. Shift X to exit. SHift O to access options. In options->Serial Port you may have to turn off hardware flow control.
```

# Build Kernel with proper Debug Symbols and Build Cross-Debugger

```bash
# Rebuild w/ debug symbols. This requires one to run the following to get to the linux build menu. In this build menu we select the various options
#    * Kernel Hacking -> Compiler Time Checks -> Build w/ Debug info 
#    * Opens up new option ... -> Provide GDB Scripts. Select yes. 
#    * Kernel Hacking -> Generic Kernel Debugging Instrumets -> KGDB
#    * ... KGDB -> KGDB over serial.
# Save and use default name and location. This populates a .config at buildroot/output/build/linux-custom/.config. 
make linux-menuconfig
cp buildroot/output/build/linux-custom/.config ./scripts/.config

# Also in the buildroot menuconfig besure to set kernel debugging options found in in build options. Also be make sure a crosss debuger is built in toolchain options. All of these options are saved below when we copy off the buildroot .config into the scripts dir.
#   * Tool Chain -> Build Cross GDB for host                     (Y) 
#   * Build Options -> Build packages with debug symbols         (N)
#   * Build Options -> Build packages wit runtime debug symbols  (N)
#   * Build Options -> Strip target binaries                     (Y)
#   * Kernel -> set .config path to "$(TOPDIR)/../scripts/.config"
make menuconfig
cp ./buildroot/.config ./scripts/buildroot.config
make all 
```

# Cross Compile for RPI

```bash
# We will just use the same method and sets of scripts to cross compile a use space app as we did in MEME OS. Before we copy over our MEME_OS scripts, we need to do some set up:
mkdir buildroot_usr_src
mkdir buildroot_kmod_src
mkdir scripts
cp buildroot/.config scripts/buildroot.config
cp buildroot/output/build/linux-custom/.config ./scripts/.config
cp buildroot/package/Config.in ./scripts/Config.in

# Now copy over the scripts from MEME_OS. We really should do this via a git sub module, but we are lazy so assume MEME_OS is in the dir level as this repo and execute
cp ../MEME_OS/scripts/build.sh ./scripts/
cp ../MEME_OS/scripts/create_empty_app.sh ./scripts/
cp ../MEME_OS/scripts/env_init.sh ./scripts
cp ../MEME_OS/scripts/rebuild_app.sh ./scripts/
cp ../MEME_OS/scripts/rebuild_linux.sh ./scripts/
cp ../MEME_OS/scripts/rebuild_kmod.sh ./scripts/

# From here the only change we made is to add a USERSPACE_APP_DIR and KMOD_APP_DIR to env init and update all references to the user space app and kmod dirs to use this variable instead of a hard coded reference. Finally we used git rev 6d86e84 of MEME_OS for these scripts. Now we can set up our first user space app to be cross compild.
source ./scripts/env_init.sh
./scripts/create_empty_app.sh ethraw

# Just create sym links in the build user src dir. We cp the source into the buildroot dir so a symlink that points to the code in the Part 1.1 will suffice and mitigates severla copies floating around.
ln -s <non-relative-path>/gen.c ./buildroot_usr_src/ethraw/src/gen.c
ln -s <non-relative-path>/sniff.c ./buildroot_usr_src/ethraw/src/sniff.c
ln -s <non-relative-path>/Makefile ./buildroot_usr_src/ethraw/src/Makfile

# Next update the ethraw.mk build script created in the create_empty_app script. Update to match that names, paths, etc of building this program. From there we can build everything
./scripts/build.sh

# In the event you change the source code or the meta data found in buildroot_usr_src one can run the following to rebuild the app and the sd image containing the app
./scripts/rebuild_app.sh ethraw

# The exe created can be found in ./buildroot/output/build/<package_name>. But the rootfs shoud now have this exe saved in it, thus copying over the new image requires just reflashing the sd card or one can copy it using a flash drive or somthing. 
```

# Attaching Host GDB to RPI Running Kernel

```bash
# Make sure kgdboc=ttyAMA0,115200 is in cmdline.txt or configure after boot on PI echo ttyS0 > /sys/module/kgdboc/parameters/kgdboc. cmdline.txt is found in the rpi-firmware package and after build is found in the first partition on the bootable media.

# We used sudo minicom -s to set all the defaults we needed i.e. port, baud, hw flow control, etc. so we could just open minicom without setting this every time. use minicom to connect to the board and run
echo g > /proc/sysrq-trigger

# On the host side open up the arm gdb with the linux debug symbols
cd buildroot
./output/host/bin/aarch64-linux-gdb ./output/build/linux-custom/vmlinux

# In gdb set baud and attach
(gdb) set serial baud 115200
(gdb) target remote /dev/ttyUSB0
```

# Sending and Recving using lrzsz

```bash
# Make sure lrzsz is installed on the host:
sudo apt-get install lrzsz

# Use menu config in buildroot to build the lrzsz package into the image. It is under packages->networking. Save off the config, build and reflash the SD
cd buildroot
make menuconfig
cp .config ../scripts/buildroot.config
cd ..
./scripts/build.sh
./scripts/flash_sd.sh

# Now on the device we can run the following to recv
rz > /dev/ttyAMA0 < /dev/ttyAMA0

# And on the host run the following to send a file
sz /path/to/file > /dev/ttyUSB0 < /dev/ttyUSB0
```
# SW Flow

The SW flow and capabilities derived in Part 1 are encapsulated by the set of scripts: 

| script | desc | comments|
| --- | --- | --- |
| `env_init.sh` | Must be sourced before using any of the scripts | - |
| `build.sh` | The proper way to call 'make all'. Copies saved configs and external packages and issues a make call | Used when new packages are added or for initial build. Will rebuild SD image based on contents on images dir. Note does issue a recompile of any package. |
| `rebuild_external_package.sh` | A light rebuild script that rebuilds just a specific external package and rebuilds the rootfs | - |
| `create_empty_*.sh` | Creates boiler plate for user apps | the .mk file contains the instructions for building, installing, etc. |
| `flash_sd.sh` | Give it the name of the block device, will unmount any partitions and reflash with current sd image | - |
| `serial_term.sh` | Connect to terminal over uart using minicom | After running once, can just use `minicom` | 
| `serial_push.sh` | Copy a file over serial to device | - |
| `serial_gdb.sh`  | Connect arch specific gdb to device over serial | Besure the device is on, logged into, in a terminal and not already in kdb |
| `serial_force_reboot.sh` | Will reboot device if it is in a terminal or in kdb | Will not work if waiting for log in |  

**Note:** to rebuild a specific package delete its build dir in output/build.  Completely remove the output dir to "nuke" the buildroot system. This will keep the package source downloaded but will force a rebuilt of everything including host tools. 

# Resources

* https://medium.com/@hungryspider/building-custom-linux-for-raspberry-pi-using-buildroot-f81efc7aa81
* https://github.com/tanner-johnson2718/MEME_OS/tree/master
* https://planeta.github.io/programming/linux-kernel-debugging/
* https://www.kernel.org/doc/html/v4.14/dev-tools/kgdb.html
* https://stackoverflow.com/questions/14584504/problems-to-connect-gdb-over-an-serial-port-to-an-kgdb-build-kernel
* https://gist.github.com/elFarto/1f9ba845e5ba3539a2c914aae1f4a1e4