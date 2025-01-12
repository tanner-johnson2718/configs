#include <linux/module.h>
#include <linux/kdb.h>
#include <linux/kernel.h>
#include <linux/kprobes.h>
#include <linux/string.h>
#include <linux/kallsyms.h>
#include <linux/phy.h>

// kln -> kall lookup name
// Input name, return addr
unsigned long (*kln_pointer)(const char *name) = NULL;
static char str_buffer_kln[KSYM_NAME_LEN] = "kallsyms_lookup_name";
static struct kprobe kp_kln = 
{
    .symbol_name = str_buffer_kln,
};

// kla -> kall lookup addr
// Input addr. Outputs symbolsize, offset, modname if its kernel module symbol
// will be filled in with the module name. namebuf must be of size 
// KSYM_NAME_LEN and will be filled and returned if symbol found. 
char* (*kla_pointer)(unsigned long addr,
			    unsigned long *symbolsize,
			    unsigned long *offset,
			    char **modname, char *namebuf) = NULL;
static char str_buffer_kla[KSYM_NAME_LEN] = "kallsyms_lookup";
static struct kprobe kp_kla =
{
    .symbol_name = str_buffer_kla,
};

static int kdb_kln(int argc, const char **argv)
{
    if (! (argc == 1))
    {
        return KDB_ARGCOUNT;   
    }
    
    kdb_printf("%s -> 0x%lx\n", argv[1], kln_pointer(argv[1]));

    return 0;
}

static int kdb_kla(int argc, const char **argv)
{
    if (! (argc == 1))
    {
        return KDB_ARGCOUNT;   
    }

    unsigned long addr = 0;
    unsigned long symbolsize = 0;
    unsigned long offset = 0;
	char namebuf[KSYM_NAME_LEN] = {0};
    char* modname = NULL;

    addr = simple_strtoul(argv[1], NULL, 16);

    char* ret = kla_pointer(addr, &symbolsize, &offset, &modname, namebuf);

    kdb_printf("0x%lx -> %s (off=%ld) (sze=%ld) (mod=%s)\n", addr, ret ? ret : "", offset, symbolsize, modname ? modname : "");

    return 0;
}

static int kdb_phy_dump(int argc, const char **argv)
{
    if (! (argc == 1))
    {
        return KDB_ARGCOUNT;   
    }

    void* addr = (void*) simple_strtoul(argv[1], NULL, 16);
    kdb_printf("Phy Dev Addr = 0x%lx\n", addr);

    struct phy_device *dev = (struct phy_device *) addr;

    kdb_printf("Phy ID          = 0x%x\n", dev->phy_id);
    kdb_printf("IRQ             = %d\n", dev->irq);
    kdb_printf("Is c45          = %d\n", dev->is_c45);
    kdb_printf("IRQ Enabled     = %d\n", dev->interrupts);
    kdb_printf("Driver          = %lx\n", dev->drv);
    kdb_printf("   Soft Reset   = %lx\n", dev->drv->soft_reset);
    kdb_printf("   Config init  = %lx\n", dev->drv->config_init);
    kdb_printf("   Get Features = %lx\n", dev->drv->probe);
    kdb_printf("   Suspend      = %lx\n", dev->drv->suspend);
    kdb_printf("   Resume       = %lx\n", dev->drv->resume);
    kdb_printf("   Config Aneg  = %lx\n", dev->drv->config_aneg);
    kdb_printf("   Aneg Done    = %lx\n", dev->drv->aneg_done);
    kdb_printf("   Read Status  = %lx\n", dev->drv->read_status);
    kdb_printf("   Ack Int      = %lx\n", dev->drv->ack_interrupt);
    kdb_printf("   Config Int   = %lx\n", dev->drv->config_intr);

    return 0;
}

static int __init kdb_hello_cmd_init(void)
{
	/*
	 * Registration of a dynamically added kdb command is done with
	 * kdb_register() with the arguments being:
	 *   1: The name of the shell command
	 *   2: The function that processes the command
	 *   3: Description of the usage of any arguments
	 *   4: Descriptive text when you run help
	 *   5: Number of characters to complete the command
	 *      0 == type the whole command
	 *      1 == match both "g" and "go" for example
	 */

    pr_info("KDB Helper Loading\n");

    kdb_register("addr", kdb_kln, "[string]",
                 "Search for addr of kernel symbol", 0);

    if(register_kprobe(&kp_kln))
    {
        pr_info("Failed to register kprobe %s\n", str_buffer_kln);
        return -1;
    }

    kln_pointer = (long unsigned int (*)(const char *)) kp_kln.addr;

    unregister_kprobe(&kp_kln);

    kdb_register("sym", kdb_kla, "[hex str]",
                 "Search for symbol given addr", 0);

    if(register_kprobe(&kp_kla))
    {
        pr_info("Failed to register kprobe %s\n", str_buffer_kla);
        return -1;
    }

    kla_pointer = (char* (*)(unsigned long,
			    unsigned long*,
			    unsigned long*,
			    char **, char *)) kp_kla.addr;

    unregister_kprobe(&kp_kla);

    kdb_register("phy", kdb_phy_dump, "[addr]",
                 "Dump Phy data structs given addr", 0);


	return 0;
}

static void __exit kdb_hello_cmd_exit(void)
{
    pr_info("KDB Helper Unloaded\n");
    kdb_unregister("addr");
    kdb_unregister("sym");
    kdb_unregister("phy");
}

module_init(kdb_hello_cmd_init);
module_exit(kdb_hello_cmd_exit);

MODULE_AUTHOR("WindRiver");
MODULE_DESCRIPTION("KDB example to add a hello command");
MODULE_LICENSE("GPL");
