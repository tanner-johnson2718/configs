# HW Requirements

* RPI 4 model B (x2)
* ESP32-WROOM-32
* Linux Laptop
* USB to serial TTL cable
* Female to Female Dupont Connectors

# Init PI OS Set up

* RPI 4 model B 2gb RAM
* Download Raspian OS at [link](https://www.raspberrypi.com/software/operating-systems/)
    * SHA256 Hash - `722305ccd11fad2e7d49f29db551b0a5d4ac10e267f33c05a620b74eea5165db`
* Flash using `dd`
* Use mouse, keyboard, and monitor for init setup
* Install openocd:

```
sudo apt-get update
sudo apt-get install -y git make pkg-config autoconf libtool libusb-1.0-0 libusb-1.0-0-dev
git clone https://github.com/openocd-org/openocd.git

git clone https://github.com/openocd-org/openocd.git
cd openocd
./bootstrap
./configure --enable-sysfsgpio --enable-bcm2835gpio
make
sudo make install
```

* cat the rpi host config file `cat tcl/interface/raspberrypi-gpio-connector.cfg` and verify the pin setup matches the table below

| PI Header PIN | BCM GPIO # | JTAG Func | ESP32 PIN | COLOR |
| --- | --- | --- | --- | --- |
| 23 |  11 |  TCK | IO13 | ORNG |
| 24 |   8 |  TMS | IO14 | BRWN |
| 19 |  10 |  TDI | IO12 | YLLW |
| 21 |   9 |  TDO | IO15 | GREN |
| 20 | GND |  GND |  GND | BLCK |
|  2 |  5v |   5v |   5v |  RED |
| 26 |   7 | TRST |  N/A | WHTE |
| 18 |  26 | SRST |  N/A | BLUE |

* Enable ssh through gui and now mouse keyboard are no longer required, we can just ssh in.

# ESP 32 Set Up

* On Host PC install ESP IDF in visual code
    * Can also follow the first steps [here](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/linux-macos-setup.html#get-started-linux-macos-first-steps)
* Save an alias in your .bashrc : `alias get_idf='. $HOME/esp/esp-idf/export.sh'`
* Copy over an example project `cp -r ~/esp/esp-idf/examples/get-started/hello-world`
* Run the following to build this example

```
cd hello-world
get_idf
idf.py set-target esp32
idf.py build
idf.py -p /dev/ttyUSB0 flash
idf.py -p /dev/ttyUSB0 monitor
```

* Doing all of the above will create a dev env on your local machine, build, flash and give you a serial monitor of an ESP-32
* Ensure the ESP 32 is connected in accordance with the pinout table in the previous section.

# OpenOCD and Remote Debugging the ESP 32

Using the ESP 32 and the hello world application, we suggest the following dev env for using openocd and gdb. Terminal 1 runs the openocd server. This can be ran with debug verbosity. This requires first ssh-ing into the pi and running the contents of the `esp32_openocd.sh` script, specifying a jtag interface rate and an IP to bind to. 

Terminal 2 runs the local host to rasp pi IP tunnel and is launched via `gdb_tunnel.sh` script, again specifying an IP. You may need to enter the password when connections go across the tunnel so its best just to keep it up.

Terminal 3 runs the telnet server that gives you cmd access into openocd. Its launched via `telnet <pi IP> 4444`. Ctl-] is the escape char. The commands you can run our documented [here](https://openocd.org/doc/html/General-Commands.html).

Terminal 4 runs gdb. `cd` in the target code repo and run `idf.py gdb`. This will launch gdb. And if you want you could have terminal 5 be your "build window" for building and flashing new images to the device.