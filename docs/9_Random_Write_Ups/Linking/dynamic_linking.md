# Hello World, Sharing is Caring

In the previous installment we looked at static linking and how globals are linked 
statically. Here we shall look at dynamic linking. Some functions, such as the `printf` 
function are part of the standard library. Instead of copying the code for these functions 
that get used across many programs into each executable, these functions are loaded into 
memory by the OS and when a program calling these funtions references them, they are 
linked and mapped at run time. In this installment we shall look at this process.

## Exercise, Make your own Print Shared Library

To start, let us make our own shared library. We will take our minimal hello world (or 
something analogous) from the previous exercise, make it a shared library for putting a 
string on the terminal, and call it in a new hello world. Our library function `my_puts()` 
is implemented in `my_puts.c`)

```C
static void my_write(int fd, char* buf, long len)
{
    asm("mov $1, %rax\n"
        "syscall\n");
}

void my_puts(char* str, long len)
{
    my_write(1, str, len);
}

```

It uses the [syscall](https://www.cs.uaf.edu/2017/fall/cs301/lecture/11_17_syscall.html) 
instruction to call the write system call on STDOUT. The literal 1 is placed into the 
`rax` register to tell the syscall intruction to do a write. The register calling 
convention for `syscall` is exactly the same for C functions, thus our `my_write` wrapper 
can simply keep the same arguements as a write system call and pass them through in the 
same registers.

Now we compile this minimal hello world with the following two commands)

* `gcc -fPIC -c my_puts.c -fno-asynchronous-unwind-tables`
    * `-fPIC` gives us PC relative addressing and is thus posistion independand
    * `-fno-asynchronous-unwind-tables` gets rid of the eh sections in the finally elf as 
       we will not use them
* `objcopy --remove-section=.note.gnu.property --remove-section=.note.GNU-stack --remove-section=.comment my_puts.o`.
    * This just strips some of the meta data so we have simplier output elf to analyze.

This produces a rather simple ELF and assembly code. It exports a single global function 
`my_puts` to be linked with our main hello world. It contains no relocation entries, an 
empty data section, and is just a symbol table and its assembly code.

Now we want to turn this object module into a shared library object. We do this with the 
following: `gcc -shared -nostdlib -o libM.so my_puts.o`. The key here is the `-shared` 
flag indicating we want to create a shared object. Note that by linux convention, shared 
libraries shard with "lib" and are suffixed with ".so". This ouputs a shared object file 
`libM.so`. Dumping the ELF we see a few new sections we have not analyzed in depth yet. 
These are the `.dynsym`, `.dynstr`, and `.dynamic` sections.

* `.dynsym` + `.dynstr`) These serve the exact same purpose as the symbol table (and 
  symbol string table) as explored in static linking. In this case, the dynamic symbol 
  table of libM.so only contains an entry for `my_puts`, gives its offset into the ELF, 
  and gives the usual meta data. Note here on key difference between the symbol table and 
  its dynamic conuter part is the dynamic symbol table actually gets loaded into memory, 
  where as the base symbol table is only stored in the file. This is obviously a key 
  distinction as we need resolve these symbols at run time. Just as in static linking, 
  objects that reference `my_puts` will get an undefined symbol to `my_puts` in their 
  respective dynamic symbol table.

* `.dynamic` is an array of [structures](https://docs.oracle.com/cd/E23824_01/html/819-0690/chapter6-42444.html) 
  that index the various sections and important details of the file used in dynamic 
  linking such as `.dynsym`, `.dynstr`, the GNU hash table, etc.

Finally we can look at our actual hello world.

```C
#include <my_puts.h>

void _start() {
    my_puts("Bra\n", 4);

    asm(
        "mov $60, %rax\n"
        "syscall"
    );
}
```

We compile this with `gcc -nostdlib -fno-asynchronous-unwind-tables -I . -L./ my_hello.c -lM -o test`. 
There are some caviets associated with this which we list below.

* First the entry point is `_start` instead of `main`. This is because we are compiling 
  without the standard library. The standard C library adds a wraper to our starting main code that handles input args, process exiting and clean up, etc. All processess by default start at the `_start` symbol (this is dictated by the linker).
* `-I .`. This flag just looks for include files in our current dir.
* `-L./`. Look for libraries in our current dir
* `-lM`. Look for library of name "libM.so". The lib and .so pre and postfix are implicitly added.
* One final gotcha is we mush add an envirmonet variable using the following command `export LD_LIBRARY_PATH=$PWD:$LD_LIBRARY_PATH`. This tells the linker to also look at our current directory for libraries at runtime.
* Finally, we must call an exit syscall "manually" using the syscall instruction as this clean up is usually done by the C standard library.

Now looking at are output file of `my_hello`. We see a few things. We see some new sections,
some new symbols, and a singular relocation entry. All these new entities in our ELF are
associated with dynamic linking. More specificlly they are associated with two structures
called the Global Offset Table (GOT) and Procedural Linkage table (PLT). We will cover this
in depth next section and thus will conclude this exercise here.

### Key Resources

* https://medium.com/@The_Mad_Zaafa/creating-and-using-dynamic-libraries-c-a9d344822ed0

## GOT and PLT

To see how the GOT and PLT are used to achieve run time linking we create a new set of test files. `libGOT.c` contains a single global varible and 2 functions. One to increment it and one to dec it. Our test driver `got.c` will simply call these functions 3 times each.

`libGOT.c`:
```C
unsigned int counter = 0;

void inc_counter()
{
    counter++;
}

void dec_counter()
{
    counter--;
}
```

`got.c`:
```C
void inc_counter();
void dec_counter();

void _start()
{
    inc_counter();
    inc_counter();
    inc_counter();
    dec_counter();
    dec_counter();
    dec_counter();
}
```

We compile this library and test driver as we did in the `my_puts` and `my_hello` example 
shown in the previous section. Let us now do a binary analysis on the output elf `got`. 
Since we know we are looking at linking and we know there are two symbols, `inc_counter` 
and `dec_counter` that need to be resolved lets start with the relocation table.

`.rela.plt`:
```
Relocation section '.rela.plt' at offset 0x3d8 contains 2 entries:
    Offset             Info             Type               Symbol's Value  Symbol's Name + Addend
0000000000002ff0  0000000100000007 R_X86_64_JUMP_SLOT     0000000000000000 dec_counter + 0
0000000000002ff8  0000000200000007 R_X86_64_JUMP_SLOT     0000000000000000 inc_counter + 0
```

The first thing to note is that unlike static linking, despite calling each function 3 
times, there is only a single relocation entry per function. The relocations point to the 
section GOT and not into the code as in the previous example. Also the index of the symbol
to relocate is its index in the dynamic symbol table not the OG symbol table. 

Next lets look at a single call to one of these functions and look at the contents of the 
`.plt.sec` section.

```
105d:	e8 de ff ff ff       	callq  1040 <inc_counter@plt>
```
```
000000000001040 <inc_counter@plt>:
    1040:	f3 0f 1e fa          	endbr64 
    1044:	f2 ff 25 ad 1f 00 00 	bnd jmpq *0x1fad(%rip)        # 2ff8 <inc_counter>
    104b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
```

We can see that the compiler has implemented calls to the library function `inc_conunter` 
by calling a wrapper function in the `.plt.sec`. This wrapper function in turn jumps to 
an address stored in the GOT section. This is the same address pointed to by the 
relocation entry. Thus we can deduce how dynamic linking works from looking at the above. 
When calling a shared library function, the compiler allocates a table to contain addresses
of there final resting location in memory. This is the GOT. The compiler also generates 
"wrapper" functions such that all calls to these functions are implemented by function 
calls into the wrapper functions. This is the PLT. Finally the compiler generates 
relocation entries for the addresses in the GOT to updated at runtime.

We should now have a warm and fuzzy for the GOT and the PLT. However as always there are 
some caviats. First we can see there is a new section we failed to look at in this example.
That is the `.plt` section. And its core purpose is to aid in a process called Lazy binding.
Secondly, we failed to explore shared libraries key property. That is the use case of 
multiple user programs sharing the same library. This is what we will explore in the next 
exercise.

### Key Resources

* [CSAPP 7.12](../Computer%20Systems%20A%20Programmers%20Perspective%20(3rd).pdf)

## Exercise, Lazy Binding and Physcial Addresses

### Lazy Binding

We have a C file, `lazy.c`. Its goal is simple. Print the contents of the GOT, call a library function, `inc_counter`, then look at the GOT one more time. This is too exemplify the process of lazy binding. This process defers the loading and mapping of shared libraries until they are called. It looks something like this:

* Call a shared library function in my code, call it `func()`.
* Compiler generates a wrapper called `func@plt`
    * This function is placed in special section before the code section
    * All calls to our library funtion, call this wrapper instead
    * It jumps to an address stored in the GOT
    * Every function call or library global gets a dedicated index in the GOT
    * This address stored in the GOT is updated at runtime
* We run our exe
* The .dynsym table, .rela.plt, and other dynamic sections are loaded into memory
    * This gives us the required meta data to resolve dynamic symbols
* We call the library function
* The address in its GOT is called (through the plt wrapper)
    * This is NOT the address of the function at first call
    * Instead the dynamic linker is invoked
* ??? weridness happens and the GOT entry is replaced with the address of the func in mem
    * We look at this in more detal next.
* Subsequent calls now point directly to function in the library resident in memory.

So let's take a look at this in action. In `lazy.c` we implement this but with the constraint that it must be `%rip` relative addressing and must not use the standard library. This requires some extra work to print pointers but simplifies the end binary for easier analsys. The function to access the GOT is shown below.

```C
// Accsesor function to get address off the GOT in mem. Note must use PIC or
// %rip relative addressing. Also not index i is a byte index.
u64 getGOT(u32 i)
{
    asm(
        "lea _GLOBAL_OFFSET_TABLE_(%rip), %rsi\n"
        "add %rsi, %rdi\n"
        "mov %rdi, %rax\n"
        "pop %rbp\n"
        "ret\n"
    );
}
```

Its a rather simple piece of assembly. Compute the address of the GOT relative to the instruction pointer. Add the byte index. Clean up the stack. Return the computed address. The first point of confusion is the `lea` instruction. If one uses a `mov` intruction it will move the value of the first entry of the GOT into `%rsi`. Using `lea` allows us to compute the address that would be accessed with a move and store it in the target register. Finally the stack clean up is a bit weird, because the boiler plate stack preamble is done for us, but since we return ourself we must do the clean up ourselves as well.

Now in our `_start` entry point we call a helper `printGOT` which calls the above `getGOT`, access the addresses returned, and prints the output cleanly to the terminal. We then call our library function `inc_coutner` and dump the GOT one more time. This produces the following output.

```
| GOT[0] | 0x5625ade28000 | 0x3ed0 |                // <- .dynamic
| GOT[1] | 0x5625ade28008 | 0x7fcbbde40190 |        // <- relo entries
| GOT[2] | 0x5625ade28010 | 0x7fcbbde29af0 |        // <- dynamic linker
| GOT[3] | 0x5625ade28018 | 0x5625ade25010 |        // <- inc_counter
| GOT[4] | 0x5625ade28020 | 0x7fcbbde0d01f |        // <- my_puts

// ... inc_counter() is called ...

| GOT[0] | 0x5625ade28000 | 0x3ed0 |                // <- .dynamic
| GOT[1] | 0x5625ade28008 | 0x7fcbbde40190 |        // <- relo entries
| GOT[2] | 0x5625ade28010 | 0x7fcbbde29af0 |        // <- dynamic linker
| GOT[3] | 0x5625ade28018 | 0x7fcbbde09000 |        // <- inc_counter (updated)
| GOT[4] | 0x5625ade28020 | 0x7fcbbde0d01f |        // <- my_puts
```
We can see from the above that the inc_counter GOT entry initially points somewhere in memory (where? see next section). We call it and its entry is updated. The values of the first 3 entries in the GOT are reserved as shown above. As a final caviat, we had to force the gcc to use lazy binding the `-z lazy` flag. gcc appears to have logic that if the number of functions to dynamically bind is low, it simply resolves them at start up. The gcc call that compiles `lazy` is shown below.

```
gcc -nostdlib -fno-asynchronous-unwind-tables -z lazy -I . -L./ lazy.c -lM -lGOT -o lazy
```

The `-lM` is to link our `my_puts` library and the rest as been covered previously. Thus in this exercise we saw how dynamic linking works to update this PLT entries at run time. In the next section we look at the mystery step of how the dynamic linker is invoked and how it specifically updates the GOT entry of shared library calls.

### .plt Section and Runtime Symbol Resolution

Our goal here is to see what happens during the first invocation of `inc_counter`. We will used gdb to do this. We will cover gdb more in depth in the next installment but for now we will simply show you the results. We also want to see what is going in the .plt section of elf.

* Launch gdb) `gdb lazy`
* Set breakpoint at start and lib fun) `b _start` and `b inc_counter`
* `r` to run util breakpoint
* Type `lay next` until we get a register and assembly split screen
* Type `ni` to step instructions, stepping over functions
* When you reach the first call to `inc_counter` use `si` to step into the function
* We get the following call stack
    * `_start`
    * `inc_counter@plt`
    * `.plt + 0x10` (GOT[3], `inc_counters GOT,  points here initially)
    * push 0 onto stack (.rela.plt index of `inc_counter`)
    * `.plt`
    * push GOT[1] onto stack
        * relocation table address
    * Now we appear to be in the dynamic linker
    * After being lost in the dynamic linker we end up with the GOT entry for `inc_counter` updated and we end up executing in this function.

Thus from executing the above and looking at the output of our `lazy` application we can see what thit `.plt` section is doing:

```
0000000000001000 <.plt>:
    1000:	ff 35 02 30 00 00    	pushq  0x3002(%rip)        # 4008 <_GLOBAL_OFFSET_TABLE_+0x8>
    1006:	f2 ff 25 03 30 00 00 	bnd jmpq *0x3003(%rip)        # 4010 <_GLOBAL_OFFSET_TABLE_+0x10>
    100d:	0f 1f 00             	nopl   (%rax)
    1010:	f3 0f 1e fa          	endbr64 
    1014:	68 00 00 00 00       	pushq  $0x0
    1019:	f2 e9 e1 ff ff ff    	bnd jmpq 1000 <.plt>
    101f:	90                   	nop
    1020:	f3 0f 1e fa          	endbr64 
    1024:	68 01 00 00 00       	pushq  $0x1
    1029:	f2 e9 d1 ff ff ff    	bnd jmpq 1000 <.plt>
    102f:	90                   	nop
```

Call `inc_counter` -> Resolves to `inc_counter@plt` -> Jump through GOT[3] -> Points to .plt+0x10 -> .plt -> Jump through GOT[2]. During this call stack, the index and address of the relocation entry for the target function are pushed onto the stack. This gives the linker what it needs to resolve and update our GOT entry.

This just about concludes the topic of dynamic linking. We have seen how the compiler sets up an exe with the GOT and PLT such that at all functions called in a shared library point to a wrapper function at compile time. Every such function gets this wrapper in `.plt.sec`. Every function also gets a relocation entry pointing to the GOT which will contain the resultant address when loaded. The first few entries of the GOT contain the address of the dynamic linker (presumably updated when a program starts up) and the address of the relocation table (known prior to runtime). The GOT entry of this function at first contains the addres of its PLT entry. Its PLT entry is code that pushes its relocation table index onto the stack then jumps to PLT[0]. This entry is code that pushes the relocation table addr onto the stack and invokes the dynamic linker. Finally the dynamic linker updates the GOT entry of the function, calls the function, and all subsequent calls skip all this nonsense and just execute the function in memory.

### Physical Addresses and Multiple Users

To conclude our look at dynamic linking, lets look at its one key useful property. Sharing a single chunk of code resident in memory between multiple programs. To explore this we add a little code at the end of `lazy.c`. We add a system call to print its PID and we a do a read system call on the STDIN fd so that the program does not exit until we enter a key stroke into the terminal. 

We run two instances of `lazy`. In linux, the procfs system interface can be used to dump the virtual pages of a process. This is done with `cat /proc/<pid>/maps`. We then make use of a program `virt_to_phys` ([code taken from here](https://stackoverflow.com/questions/5748492/is-there-any-api-for-determining-the-physical-address-from-virtual-address-in-li)) to convert the pages of each process that are associated with `libGOT` into physical addresses. Finally we can compare and see what pages each process shares and what parts of libGOT are not shared. Note, we will cover topics such as virual memory, procfs, files, etc in more detail at a later timer. For now, focus on using these concepts to highlight how libGOT gets shared and what sections do not get shared.


**Proc 1**
* PID = 1044641
* Lib GOT Virt Pages:
```
7f476cc30000-7f476cc31000 r--p 00000000 08:02 8787599          /home/.../libGOT.so
7f476cc31000-7f476cc32000 r-xp 00001000 08:02 8787599          /home/.../libGOT.so
7f476cc32000-7f476cc33000 r--p 00002000 08:02 8787599          /home/.../libGOT.so
7f476cc33000-7f476cc34000 rw-p 00003000 08:02 8787599          /home/.../libGOT.so
```
* Physical Page Mapping)
    * 0x7f476cc30000   ->   0x2b932000
    * 0x7f476cc31000   ->   0x28e83000
    * 0x7f476cc32000   ->   0x7c5d0000
    * 0x7f476cc33000   ->   0x7c4f9000


**Proc 2**
* PID = 1045109
* Lib GOT Virt Pages:
```
7f2355653000-7f2355654000 r--p 00000000 08:02 8787599          /home/.../libGOT.so
7f2355654000-7f2355655000 r-xp 00001000 08:02 8787599          /home/.../libGOT.so
7f2355655000-7f2355656000 r--p 00002000 08:02 8787599          /home/.../libGOT.so
7f2355656000-7f2355657000 rw-p 00003000 08:02 8787599          /home/.../libGOT.so
```
* Physical Page Mapping)
    * 0x7f2355653000   ->   0x2b932000
    * 0x7f2355654000   ->   0x28e83000
    * 0x7f2355655000   ->   0x1aa5de000
    * 0x7f2355656000   ->   0x24a351000

**libGOT.so Program Headers**
```
Program Headers:
  Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
  LOAD           0x000000 0x0000000000000000 0x0000000000000000 0x000380 0x000380 R   0x1000
  LOAD           0x001000 0x0000000000001000 0x0000000000001000 0x000040 0x000040 R E 0x1000
  LOAD           0x002000 0x0000000000002000 0x0000000000002000 0x000000 0x000000 R   0x1000
  LOAD           0x002f18 0x0000000000002f18 0x0000000000002f18 0x000100 0x000108 RW  0x1000
  DYNAMIC        0x002f18 0x0000000000002f18 0x0000000000002f18 0x0000e0 0x0000e0 RW  0x8
  NOTE           0x000270 0x0000000000000270 0x0000000000000270 0x000020 0x000020 R   0x8
  NOTE           0x000290 0x0000000000000290 0x0000000000000290 0x000024 0x000024 R   0x4
  GNU_PROPERTY   0x000270 0x0000000000000270 0x0000000000000270 0x000020 0x000020 R   0x8
  GNU_STACK      0x000000 0x0000000000000000 0x0000000000000000 0x000000 0x000000 RW  0x10
  GNU_RELRO      0x002f18 0x0000000000002f18 0x0000000000002f18 0x0000e8 0x0000e8 R   0x1

 Section to Segment mapping:
  Segment Sections...
   00     .note.gnu.property .note.gnu.build-id .gnu.hash .dynsym .dynstr .rela.dyn 
   01     .text 
   02     .eh_frame 
   03     .dynamic .got .got.plt .bss 
   04     .dynamic 
   05     .note.gnu.property 
   06     .note.gnu.build-id 
   07     .note.gnu.property 
   08     
   09     .dynamic .got 
```

We can see from the above that the 4 load segmenets found in the `libGOT.so` library correspond with the 4 pages found in each processes virtual. Moreover, we see a key pattern. The first two pages / segments are shared, the last two get copied such that each process gets its own unique copy. Now from the Section to Segment mapping we can see that its things such as meta data, the symbol table, and most importantly the code is what gets shared. The data sections and GOT are copied. This makes sense. We want to reuse the code, however, each invocation of a shared library should result in a seperate data section. My program using some shared library should not mess with the state of your program using the same shared library. 

## Clean Up

We will be moving on from linking and have just spent a lot of time exploring it. Below are a few clean up topics that are useful but did not fit neatly into our previous dicussions. 

At the end of the day, linking is simply how two C files get patched together such that code and state from one can be used by the other. We have seen this process of patching is not so straight forward. However, it can be neatly summarized by looking at the data structures involved.

1) Symbol Table. A list of all static and global variables, functions, etc. That a program either implements or needs.

2) Relocation Table. For every instance of function or global that is needed, the compiler puts an entry in this table saying "Hey I need this reference to a function when its found to be updated here in my code".

3) GOT. The GOT is just an array of addresses. When referencing a shared library, every function or global from that library gets one index in the GOT such that all references in the code all point to the GOT. The GOT will be updated with the runtime address of those shared library symbols.

4) PLT. The PLT is used for resolving shared library functions. It consists of a wrapper function so that all calls to shared library functions call this wrapper function. The wrapper function points to some assembly uniqie to shared library function. This assembly pushes the index of the function that needs resolving and invokes the dynamic linker.

If you can deeply understand the above data stuctures, then you can master the topic of linking.

### System Shared Libraries

* **Q** What shared system libraries are currently in use?
    * `sudo awk '$NF!~/\.so/{next} {$0=$NF} !a[$0]++' /proc/*/maps`


### Linker Script Clean up 

Ideally we'd have an in depth exploration here. However, we leave it as a topic for later disucssion. 
