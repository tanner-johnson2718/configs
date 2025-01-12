# ESP 32 Getting UART 

* Copy `esp/esp-idf/examples/peripherals/uart/uart_echo`
* Use `get_idf && idf.py menuconfig` to verify params
    * UART Port = 2
    * RX Pin = 16
    * TX Pin = 17
    * Baud = 115200
* Now this will set up the TX and RX UART pins on the boards header to work
* Connect TX <-> in accordance with the pin out in the [readme](../README.md)
* `printf` and `ESP_LOGI(TAG, "Recv str: %s", (char *) data);` still send to UART0 over usb
