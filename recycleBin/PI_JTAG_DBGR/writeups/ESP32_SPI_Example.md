# ESP 32 SPI Slave Example

* Copied `esp/.../spi_slave_reciever` example
* Deleted everything not targeting the base esp32
* Deleted the whole handshake gpio pin BS
* The [ESP 32 TRM](../Docs/esp32_technical_reference_manual_en.pdf) and this example implies we can use any gpio pins for the SPI config so we use the following ..
* Set up the following pin assignments 

| ESP32 Pin | SPI Func | Color |
| --- | --- | --- |
| 32 | MISO | BRWN |
| 35 | CS_0 |  RED |
| 34 | MOSI | ORNG |
| 33 | SCLK | YLLW | 

* use 10Mhz as speed