# ESP32 System Overview

Welcome to ESP 32 Deluminator system design and overview. The goal of this document is to describe and provide a reference for some of the system config and design our esp32 project will be using. To Build, flash, and commonicate with esp32 over USB UART see [here](https://github.com/tanner-johnson2718/PI_JTAG_DBGR/blob/master/writeups/Init_PI_JTAG_Test.md#esp-32-set-up). All the src location is located at [esp32_build](../esp32_build/).


| **TABLE OF CONTENTS** |
| --- |
| [Serial Based REPL](./esp32_sys_overview.md#repl) |
| [User Iterface](./esp32_sys_overview.md#user-interface) |
| [Wifi](./esp32_sys_overview.md#wifis\) |
| [Flash Memory](./esp32_sys_overview.md#flash-memory) |
| [Appendix](./esp32_sys_overview.md#system-boot-up) |

# REPL

* [Implementation](./esp32_build/main/repl.c)
* [Header File with some extra details](./esp32_build/main/repl.h)
* Based on esp-idf example `system/console/basic/example` and uses the `esp_console` console API
* The header file shows one how to use it but its pretty straight forward
* With this module we get a interactive console to run any commands we register
* Also, this gives us a debug log - Use `ESP32_LOGI` and `ESP32_LOGE` to log events over the console


# User Interface

* [Implementation](./esp32_build/main/user_interface.c)
* [Header with an high level explanation](./esp32_build/main/user_interface.h)

## I2C Library for LCD 2004 w/ PCF8547T IO Expander

* https://github.com/maxsydney/ESP32-HD44780
* Take c and header file from this and add the c file to the CMakeLists.txt SRC list
* set master clock to 500000
* Use the following Pinout
* LCD ADDR of 0x27

## Encoder Library

* https://github.com/UncleRus/esp-idf-lib/tree/master/components/encoder
* Took implementation from above and used as is.
* Uses a timer to poll the button and rotary state
* Take in an event Q and publishes events

# Wifi

The wifi module inits to two [net_if interfaces](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/network/esp_netif.html). One for a station and one for an AP. This allows to be both a host and client. We init the [wifi interface](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/network/esp_wifi.html) in dual STA / AP mode. Our module contains several internal data structures.

* A list of wifi access points with both UI and REPL commands to update
* A "General Purpose" timer that can be started and pointed to by the UI or REPL commands to post logging data to their repective mediums
* A notion of "targeting" an AP
* When an AP is targeted we can launch the packet sniffer that:
    * Logs MACs seen in the active MAC data structure
    * Logs Strengths of packets seen
    * Logs in-RAM any WPA2 handshake it sees
* When the active MAC is cleared the in-RAM WPA2 handshake packets are dumped to disk
    * This a raw binary dump where the first 8 bytes are the sizes of the EAPOL packets (2 byte sizes)
    * The remainder is a binary dump of packet, appended to the buffer with no padding.
* Finally we export both UI and REPL commands for interacting with these data structures and processes in a logial way

# Flash Memory

* [Implementation](./esp32_build/main/flash_man.c)
* [Header File](./esp32_build/main/flash_man.h)
* For now all our flash memory module does is init two subsyetems that may be used through other API
* (1) NVS - Stores key pairs on NVS partion.
    * Used by wifi module to store PHY params
    * The api is the builtin esp32 nvs api
* (2) SPIFFS - Stores files in a flat dir struct
    * Used to to store console command history
    * Will be used by wifi module to store packet dumps
    * Provides a POSIX file interface i.e. open, read, etc.

## Files

| File name | Desc |
| --- | --- |
| `history.txt` | List of command history entered into the REPL |
| `event.txt` | Debug info for default event loop. Must run user defined cmd `dump_event_log` to update |
| `ssid_name.pkt` | Packet dump saves from the packet sniffer. Stores raw eapol packets | 

## Layout

| Addr Range | Desc | Comment |
| --- | --- | --- |
| `0x0000 - 0x0FFF` | All `0xFF`s | ? |
| `0x1000 - 0x8FFF` | Second Stage Boot loader | image at `build/bootloader/bootloader.bin` |
| `0x9000 - 0xAFFF` | Partition Table | image at `build/partition_table/partition-table.bin` |
| `0xA000 - 0xAFFF` | Phy Init Data | - |
| `0xB000 - 0x1_FFFF` | NVS | See Below | 
| `0x2_0000 - 0x11_FFFF` | Application image | Can extend size as needed |
| `0x12_0000 - 0x400000` | SPIFFS parition | Takes up rest of flash memory |

* [Partition Table API Guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/partition-tables.html)
* `esptool.py read_flash` subcommand
* [JTAG Flash reading](https://github.com/tanner-johnson2718/PI_JTAG_DBGR/blob/master/writeups/Reverse_Engineer_Example.md)

## NVS

* Basically just allows one to store key-value pairs in a dedicated namespace
* We only initialize it to be used by the esp wifi code
* Usage is as follows:

```C
#include "nvs_flash.h"
#include "nvs.h"

// MAKE SURE TO CHECK ERRORS, this is for brevity
nvs_flash_init();
nvs_open("ns", NVS_READWRITE, &my_handle);
nvs_set_i32(my_handle, "key", val);
nvs_get_i32(my_handle, "key", &val);
```

* [NVS](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/storage/nvs_flash.html)

## File systems on Flash Memory

* Tried using FAT FS but it got corrupted rather quickly
* Using SPIFFS which does not allow dir

```C
#include "esp_spiffs.h"

// Easy mounting helper to mount fs
esp_vfs_spiffs_register(&config);
esp_spiffs_check(config.partition_label);
esp_spiffs_info(conf.partition_label, &total, &used);
esp_vfs_spiffs_unregister(conf.partition_label);

// Now the vfs gives POSIX complient like read, write, open, close and delete
FILE* f = fopen("/spiffs/hello.txt", "w");
fgets(line, sizeof(line), f); fread(...);
fwrite(...);
remove(path);
fclose(f);
```

* [SPIFFS API ref](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/storage/spiffs.html)

# Appendix
## System Boot Up

* Bootstage 1
    * Reset vector code located in ROM and is unchangable
    * Based on type of reset certain registers dictate boot flow
    * In the usual case the 2nd stage boot loader is called from addr `0x1000`
    * Reads the Boot Loader header and loads 3 memory regions associated with the 2nd stage boot loader:
    * The passes control over to the loaded 2nd stage bootloader with entry at `0x4008_0688`

| Seg | Addr | Len | Target | Comment | 
| --- | --- | --- | --- | --- |
| .dram0.bss, .dram0.data, .dram0.rodata | `0x3FFF_0000` | `0x27FC` | Internal SRAM 1 | .dram0.bss is `0x30` in len and this seg is actually loaded at `0x3FFF_0030` |
| .iram_loader.text | `0x4007_8000` | `0x421B` | Internal SRAM 0 | - |
| .iram.text .iram.text | `0x4008_0400` | `0x10A1`| Internal SRAM 0 | - |

* Boot Stage 2
    * Maps First `0x1_0000` of flash to `0x3F40_0000`, mapping the partition table to `0x3F40_9000`
        * This makes sense why reading the virt addrs on the jtag only allowed us read the first `0x1_0000` bytes
    * Loads in the app image in accorance with the partition table and maps the following segments shown below
    * Remaps first `0x1_0000` bytes at addr `0x2_000` (the app) of flash to `0x3F40_0000`.
        * This maps over the part table mapping
        * Only maps `0x1_000` bytes to map the ro_data from the app image into the address space
    * Maps `0x4_0000` bytes starting at flash offset `0x3_0000` (this is `0x1_0000` bytes offset into the app.bin image) to vaddr `0x400D_0000`.
        * This mapping happens twice and both times we get a log message like this: `0x400d0020: _stext at ??:?`
        * Would need to look closer but my hypothesis is this is from the APP CPU, which in reset until app code starts, is getting pointed to this addr and this is where the messsage comes from
    * Finally it verifys the app image and uses the load addr contained in it to start the PRO CPU at address `0x4008_16DC` which is the function `call_start_cpu0`

| Seg | Addr | Len | Target | Comment |
| --- | --- | --- | --- | --- |
| .flash.appdesc .flash.rodata | `0x3f400020` | `0x0e710` | External Flash | - |
| .rtc.dummy .rtc.force_fast | `0x3ff80000` | `0x00068` | RTC Fast Memory | - |
| .dram0.data .noinit .dram0.bss | `0x3ffb0000` | `0x02c08` | Internal SRAM 2 | - |
| .iram0.vectors .iram0.text .iram0.text_end  | `0x40080000` | `0x0ecac` | Internal SRAM 0 | Appears to cache important systems functions that probably are called from interrupt contexts. Can cat and grep the symbol table looking for entiers in section ` 9 ` which is the iram.text section |
| .rtc.text | `0x400c0000` | `0x00063` | RTC Fast Memory | - |
| .flash.text | `0x400d0020` | `0x31757` | External Flash | - |
| .rtc_slow_reserved | `0x50001fe8` | `0x00018` | RTC Slow | - |

* Application start up
    * Application code starts `call_start_cpu0` which is located at `esp-idf/components/esp_system/port/cpu_start.c`
        * This appears to do alot of early hardware init
        * This also starts the other core
        * Both cores end their init with the `SYS_STARTUP_FN` macro
    * Since we are in app code we can use gdb to peer into this start up code
        * todo this don't use the `idf.py gdb` call as it auto inserts a break point at app_main and continues after reset
        * Instead use the provided [gdb script](./gdb_start.sh)
    * cpu0 enters `start_cpu0()` in `startup.c`
        * cpu0 calls `do_core_init()` in `startup.c`
            * cpu0 calls `heap_caps_init()` in `heap/heap_caps_init.c`
                * heap init uses the `heap_memory_layout.h` API and global structs to find all the RAM regions such that it is not used by static data, used by ROM code, or reserved by a component using the `SOC_RESERVE_MEMORY_REGION()` macro.
                * It then condenses these memory regions down, each regions and allocates heaps metadat for that heap in that region.
            * `do_core_init` then does all sorts of init tasks: timers, secure boot verification, etc, etc.
        * cpu0 then calls `do_global_ctors` which allows functions added to the init array at build time to be ran. See [here](https://github.com/tanner-johnson2718/MEME_OS_3/tree/main/Loading) for details on init functions and their linking.
        * Finally it secondary init which passes control over to other cores so if they have init todo they may
    * cpu0 calls `esp_startup_start_app`
        * starts dameon tasks
        * starts "main task" pinned to cpu0
            * calls our app main
        * starts scheduler `vTaskStartScheduler();`
    * cpu1 started ite init late in cpu0's init.
    * cpu1 calls `esp_startup_start_app_other_cores`
        * starts dameon tasks
        * waits for scheduler on cpu0 to be finished
        * starts scheduler `xPortStartScheduler();`

[Start Up Guide](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/startup.html)

## Tasks / FreeRTOS

* Create
* Delete
* Delay
* Semaphore
* Tasks list on our system

* [FreeRTOS API Reference](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/system/freertos.html)
* [Vanilla RTOS Ref](https://www.freertos.org/RTOS.html)

## Event Loop API

The event loop API is a built in message passing async system built into the esp 32 dev env. There are two main subsytems:

* User defined - make your own event loop
* Default - creation and deletion hidden, used by WIFI API and you can use it to.

The basic API is shown below for the default event loop but the semantics hold for user defined ones

```C
#include "esp_event.h"

// Unclear what exactly the default settings are (define in the esp_event_loop_args_t struct)
// But these bad bois create and clean up the default event loop
esp_event_loop_create_default();
esp_event_loop_delete_default();

// Define a base to identify your class of events. Define an enum to map event_ids to enumerators
ESP_EVENT_DECLARE_BASE(MY_EVENT_BASE);
enum {                                       
    ID0;
    ID1;
};

// Here we can define a cb to be called when an event happens. Note we have macros for
// all event bases and/or all event ids.
void func(void* handler_args, esp_event_base_t base, int32_t id, void* event_data);
esp_event_handler_register(MY_EVENT_BASE, ID, func, arg);

// Now we can post events (even in an ISR context)
esp_event_post(MY_EVENT_BASE, ID, const void *event_data, size_t event_data_size, TickType_t ticks_to_wait);

// Use this with CONFIG_ESP_EVENT_LOOP_PROFILING enabled
esp_event_dump(FILE *file);
```

* [Event Loop API](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/system/esp_event.html)]
* Note Event loop appears to only dispatch one thread to process events
* Meaning an event handler need not handle reentrant cases cause it will never reenter 

## Push button with Debouncing

* Here is a basic walk through for setting up a event based push button debouncer
* Connct D13 to grount through button with 20kohm resitor
    * [D13] <---> Res <---> Switch <---> GND
* Configure the pin

```C
gpio_config_t gpio_conf = {};
gpio_conf.mode = GPIO_MODE_INPUT;
gpio_conf.pin_bit_mask = (1ULL << BUTTON_PIN);
gpio_conf.pull_up_en = 1;
gpio_conf.intr_type = GPIO_INTR_ANYEDGE;
gpio_config(&gpio_conf);
```

* Set up the ISR and a task to listen for events added by the ISR onto a queue
* We register an isr that uses in ISR context add to Q function.
* It adds whatever data was specified upon registry of the isr
    * usually an IO num to indicate which pin triggered the ISR
* Then we create a task that blocks until something is added to the queue

```C
static void IRAM_ATTR gpio_isr_handler(void* arg)
{
    uint32_t a = 0;

    // Copies frome &a to the Q the number bytes indicated upon Q creation
    xQueueSendFromISR(gpio_evt_queue, &a, NULL);
}

static void event_q_poller(void* arg)
{
    uint32_t io_num;
    for(;;)
    {
        if(xQueueReceive(gpio_evt_queue, &io_num, portMAX_DELAY)) {
            // process io event here
        }
    }
}

gpio_install_isr_service(0);
gpio_isr_handler_add(BUTTON_PIN, gpio_isr_handler, NULL);
gpio_evt_queue = xQueueCreate(10, sizeof(uint32_t));
xTaskCreate(event_q_poller, "event_q_poller", 2048, NULL, EVENT_QUEUE_PRIO, NULL);
```
