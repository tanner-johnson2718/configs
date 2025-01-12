# PI JTAG Debugger

Use a Raspberry PI to as a JTAG debugger!!

# JTAG

* [Init Set up of PI JTAG Debugger](./writeups/Init_PI_JTAG_Test.md)

| PI Header PIN | BCM GPIO # | JTAG Func | COLOR |
| --- | --- | --- | --- |
| 23 |  11 |  TCK | ORNG |
| 24 |   8 |  TMS | BRWN |
| 19 |  10 |  TDI | YLLW |
| 21 |   9 |  TDO | GREN |
| 26 |   7 | TRST | WHTE |
| 18 |  26 | SRST | BLUE |
| 20 | GND |  GND | BLCK |

* [Targeting and Setting up an ESP32 Dev Env](./writeups/Init_PI_JTAG_Test.md#esp-32-set-up)
* [Targeting an RPI 4](./writeups/RPI4_JTAG_Target.md)
* [Using JTAG to reverse engineer a esp32](./writeups/Reverse_Engineer_Example.md)

# UART

* On the pi make sure `/boot/confit.txt` has `enable_uart=1`
    * Can do this by `sudo raspi-config` -> Serial Config 
* This creates device `/dev/ttyS0` as serial device for the GPIO header UART

| PI Header PIN | BCM GPIO # | UART Func | COLOR |
| --- | --- | --- | --- |
|  6 |     GND | GND | BLCK |
|  8 | GPIO 14 |  TX | WHTE |
| 10 | GPIO 15 |  RX | GRAY |

* [ESP32 and PI aux UART Setup](./writeups/ESP32_GPIO_UART.md)

# SPI

* On the pi use the gui, menu->Preferences->Raspberry Pin Config and turn on SPI
* Reboot
* Run `sudo raspi-config` -> interface options -> enable SPI
* Reboot
* Open `/boot/config.txt` and add `dtoverlay=spi6-1cs,cs0_pin=16`
* Can double check with `raspi-gpio get`
* Creates device `/dev/spidev6.0`
* See [docs](./Docs/draft_spidev_doc.pdf) for python API

| PI Header PIN | BCM GPIO # | SPI Func | COLOR |
| --- | --- | --- | --- |
| 36 | GPIO 16 | CS_0 |  RED |
| 35 | GPIO 19 | MISO |  TAN |
| 38 | GPIO 20 | MOSI | ORNG |
| 40 | GPIO 21 | SCLK | YLLW |

* [ESP 32 SPI Example](./writeups/ESP32_SPI_Example.md)

# Osc Scope

* [Setting up the Osc Scope SW](./writeups/install_osc_scope.md)

# NFS Client

```
sudo apt update
sudo apt install nfs-common
sudo mkdir ~/nfs_root
sudo mount -t nfs 192.168.0.14:/home/hipi/nfs_root ~/nfs_root
```

# Datasheets and Refs

* [BCM2711](./Docs/bcm2711-peripherals.pdf)
* [RPI Schematics](./Docs/raspberry-pi-4-reduced-schematics.pdf)
* [ESP32 Wroom 32 Data Sheet](./Docs/esp32-wroom-32_datasheet_en.pdf)
* [RPI OpenOCD Host Blog](https://blog.wokwi.com/gdb-debugging-esp32-using-raspberry-pi/)
* [Set up RPI as JTAG Target](https://sysprogs.com/VisualKernel/tutorials/raspberry/jtagsetup/)
* [Set up RPI as JTAG Target 2](https://www.vinnie.work/blog/2020-11-06-baremetal-rpi4-setup)
* [OpenOCD Official Doc](./Docs/openocd.pdf)
* [Arm A72 TRM](./Docs/cortex_a72_mpcore_trm_100095_0001_02_en.pdf)
* [ESP 32 Programming Model](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/index.html)
* [ESP 32 TRM](./Docs/esp32_technical_reference_manual_en.pdf)
* [ESP 32 Pinout](./Docs/ESP32-36-Pin-Pinout.jpg)
* [SpiDev Doc](./Docs/draft_spidev_doc.pdf)
