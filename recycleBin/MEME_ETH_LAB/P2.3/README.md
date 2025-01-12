# BCM Genet Driver Reverse Engineer

The goal of this installation is to figure out how this driver works. From our [first go around](./init_notes.md) we could see the probe and remove driver functions as well as netdev_ops functions that are actually called to use this device to process packets. The `skb_buff`, `net_dev`, and `bcmgenet_priv` are the data structures of primary interest. Some pointed questions to guide this are:

* Memory locations. fd580000? base pointer in private bcm struct?
    * Stat Registers?
* Tx/Rx queues?
* Where does the packet actually reside in the socket buffer
* DMA?
* IRQs
* Need to get into the probe function

# Reading stat registers (MIB - Management Information base)

```
base = 0xffffffc011d70000     (will change)
umac_off = 0x800
mib_stat_start = 0x400
```

* Got base addr:
    * add a bp at `bcmgenet_xmit`.
    * Set another bp a few instructions down st the priv var was in scope
    * Then `print priv->base`
* `bcmgenet_update_mib_counters` reads and updates thes counters
* In GDB `x/100xb $base+0x800+0x400` where we set base via `set $base = 0xffffffc011d70000`
* `struct bcmgenet_stats bcmgenet_gstrings_stats` defines which variables are MIB
* The other stat variables appear to be updated in software `bcmgenet_get_stats`
    * These appear to be aggregate stats calculated from the sum of each tx/rx queue counts
* `ethtool --statistics eth0` causes both `bcmgenet_update_mib_counters` and `bcmgenet_get_stats` to trigger

# Kmod to Convert to physical addrs

We will create a kernel module to access the following function to convert to physical addresses:

```C
#include <asm/memory.h>

phys_addr_t virt_to_phys(const volatile void *x);
```

It will use a sysfs interface where we write an adress to a `v_addr` file and the corresponding physical address can be read from the `p_addr` files. The external package `v2p` implements this sysfs interface and address translation. It creates a folder `/sys/kernel/v2p` which houses our `v_addr` and `p_addr` files. Using `cat` and `echo` we can easily read and write to these files. Using this module we can see what the physical address of our base pointer was in the above example.

```bash
> echo 0xffffffc011d70000 > /sys/kernel/v2p/v_addr 
> cat /sys/kernel/v2p/p_addr 
0x1f70000

> cat /proc/iomem
00000000-39bfffff : System RAM
  00000000-00000fff : reserved
  00200000-0112ffff : Kernel code
  01130000-014bffff : reserved
  014c0000-017effff : Kernel data
  1ac00000-2ebfffff : reserved
  2eff2000-2effffff : reserved
  35c00000-39bfffff : reserved
....
```

Oddly enough the address falls between two mapped regions of memory but itself appears to not be mapped?

# IOMEM

* https://www.kernel.org/doc/html/v5.10/core-api/bus-virt-phys-mapping.html
* https://lwn.net/Articles/653585/
* `arch/arm64/include/asm/memory.h` -> virt_to_phys with comment not use in driver code
    * points to `include/linux/dma-mapping.h`
* `arch/arm64/include/asm/io.h` -> intersting stuff in that there file