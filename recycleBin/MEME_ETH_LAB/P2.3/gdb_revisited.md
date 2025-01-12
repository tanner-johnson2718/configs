# GDB OC Revisited

The goal here to revisit using GDB over UART as writing kdb modules to dump linux structs is silly when gdb can do it. Before reading this, make sure to check out the following for context:

* [GDB Cheat Sheet 1.0](https://github.com/tanner-johnson2718/MEME_OS_3/tree/main/Appendix/GDB)
* [Init RPI and Script Set up](../P1.2/README.md)
* [KDB](../P2.2/README.md#setting-up-the-debug-environment)
* [KGDBOC Doc](https://docs.kernel.org/dev-tools/kgdb.html)
* [Vid on KDB and KGDB](https://www.youtube.com/watch?v=HBOwoSyRmys)

## Quirks of GDBOC and init setup

* Using the image as is, add `kgdboc=ttyAMA0 kgdbwait` to the cmdline.txt in the boot partition
* use `connect_gdb.sh` to connect the gdb console to the remote target
* Add initial breakpoints you wish to `gdb_cmds.txt`
* DO NOT step it does weirdness
    * Given the kernel's complexity we do not get source or intruction level stepping. Its an inate limitation
    * To get to arbitrary code, our prefered method is to break at the high level symbol, find the address of an instruction close to where you want to poke around in the function, then set that as a break point, clearing the initial break point.
    * NOTE that when you enter the second break point you are not in the same function call or exeution context as when you hit the start of the fucntion. You do not have fine grain control.

# KDMX and the new Debug ENV

Stands for KGDB-mux. Gives us two psdeou terminals that multiplex the single shared serial connection to the PI. This allows us to have both a serial terminal and KGDB over serial as well. Set up:

```bash
cd ./scripts
git clone git://git.kernel.org/pub/scm/utils/kernel/kgdb/agent-proxy.git/
cd agent-proxy/kdmx
make
```

Now we can set up a pretty sick debug environment with 3 terminals, numbered 1 to 3 from left to right. In terminal 1:

```bash
cd ./scripts/agent-proxy/kdmx
./kdmx -n -d -p/dev/ttyUSB0 -b115200
serial port: /dev/ttyUSB0
Initalizing the serial port to 115200 8n1
/dev/pts/1 is slave pty for terminal emulator
/dev/pts/2 is slave pty for gdb

Use <ctrl>C to terminate program

```

This gives us a terminal running the kdmx program with debug output. Kdmx is not the most polished software ever created but is super convientent and this terminal will let us now if our pts devices are changed. Now in the second terminal:

```bash
source ./scripts/env_init.sh
minicom -o -d -p /dev/pts/1
```

This gives us our terminal to enter kdb or interface with the command-line. For our 3rd terminal we open gdb:

```bash
# note before running this we cat the gdb_cmds.txt file to make sure our 
# targeted port matches the pts dev created by kdmx
cat ./scripts/gdb_cmds.txt
source ./scripts/env_init.sh
./scripts/connect_gdb.sh
```

Note that before we connect gdb ensure that kdb was triggered on terminal 2 (`echo g > /proc/sysrq-trigger`). Then in GDB we can debug and continue execution. To pass control back to GDB simply envoke kdb again. Invoking kdb will pass control to GDB and you cannot use both at the same time. To make it so invoking kdb actually brings you to the kdb terminal, pass control to GDB and then simply quit. This appears to be reversible and you invoke gdb again by simply connecting again.

## Resource

* [Kdmx Site](https://elinux.org/Kdmx)

# lx-cmds

The lx-commands give one powerful tools for examining the kenrel in GDB. See [here](https://docs.kernel.org/dev-tools/gdb-kernel-debugging.html) for the official reference. The required config and init commands required were shown earlier [here](../P1.2/README.md#build-kernel-with-proper-debug-symbols-and-build-cross-debugger). But we want to make a dedicated section for discussion of these scripts. Running lx- then hitting tab in the GDB prompt will give a list of what is avaiable.

# GDB Cheat Sheet 2.0

[reference](https://darkdust.net/files/GDB%20Cheat%20Sheet.pdf)

| Command | Description | Comment |
| --- | --- | --- |
| `starti` | Start executing at very first instruction | Usually Dynamic Linker _start function |
| `b <addr/symbol>` | Add break point at address or symbol | - |
| `maint info breakpoints` | See all break points | - |
| `delete <i>` | Delete Breakpoint of given index | - |
| `ni` | Next instruction, stepping over function calls | - |
| `si` | Next instruction, stepping INTO function calls | - |
| `x/<N><f><u>` | N = Num units, f format i.e. x for hex, s for string, etc, u = unit. u almost always is b for bytes. | - |
| `info inferiors` | Get PID | - | 
| `info proc mappings` | See Process Memory Mappings | - |
| `lay next` | Cycle default Layouts | - |
| `tui disable` | Go back to just the gdb console | - |
| `info files` | Section Address Mappings | Good for finding GOT, PLT, etc in process memory map |
| `info reg` | Print registers | - |
| `p $<reg>` | Print a specific register | Pretty output with symbol resoltion. Good for seeing stack pointers in particular |
| `info address <symbol>` | Print the address of a symbol | - |
| `disas <none/symbol/addr>` | Print disassembly of passed symbol or address | - |
| `info variables` | Prints all local and global vars | DONT DO, huge list |
| `info local` | See local variables | - |
| `info args` | See function input args | - |
| `info symbol <addr>` | Given an address look it up in the symbol table | - | 
| `info address <symbol>` | Given a symbol look up its addr | - | 
| `set print pretty on` | Prints variables and data structures all pretty like | - |
| `print <var>` | Print a variable | - | 
| `up/down <n>` | Move up or down the call stack n frames | - |
| `set $x=7` | Define a variable x | - |
| `disable / enable <n>` | Enable or Disable bp n | - |