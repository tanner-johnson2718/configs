# Hello World, What did you give me?

* Code)

```C
#include <stdio.h>

int main(int argc, char** argv)
{
    printf("Hello World\n");
    return 0;
}
```

* Build) `gcc -o hello hello.c`.
* Execute) `./hello`

# Overview

We will use the simple hello world exectuable as a means to examine the format and contents of an ELF executable. This is one of the first questions one might have after creating a hello world. The 4 or so lines of the hello world can be explained away pretty easily even though there is alot going on, but its not so easy to explain away the fact that the hello world executable is several KB. Why is this? If you are reading this you probably are faintly aware of assembly and have done a dissembly of an executable. When one disasembles the hello world exe its very clear there is more going on here then first meets the eye. Thus this is where we begin our adventure. We will look at the ELF format and the contents of an executable. This will lead to way way more questions then get answered, but this property makes it a good starting point for this project.

**This topic is much less structered then the following topics**. Use this section as means to raise questions. The key take away is the following:

* Understand the diagram below showing the ELF format
* Understand an executalble is segmented into code (.text), data (.data, .bss), and other sections.
* Most of these ELF segements and sections aid in the process of linking.
# Examining the output (ELF Format and Contents)

![alt text](Elf-layout--en.svg.png)

* Above is a diagram showing how an ELF file is layed out (as saved on disk)
* `readelf -a hello` dumps entire output file and gives human readable overview of its contents
* The ELF file contents are defined by C structures declared in `/usr/include/elf.h`. 
* The ELF header contains meta data on the exe. More importantly it points to the program header and section header of the ELF, the two ways the contents of an ELF are organized or structured.

```
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              DYN (Shared object file)
  Machine:                           Advanced Micro Devices X86-64
  Version:                           0x1
  Entry point address:               0x1060
  Start of program headers:          64 (bytes into file)
  Start of section headers:          14712 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           56 (bytes)
  Number of program headers:         13
  Size of section headers:           64 (bytes)
  Number of section headers:         31
  Section header string table index: 30
```

## Section Header:
```
$ readelf -S --wide hello
There are 31 section headers, starting at offset 0x3978:

Section Headers:
  [Nr] Name              Type            Address          Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            0000000000000000 000000 000000 00      0   0  0
  [ 1] .interp           PROGBITS        0000000000000318 000318 00001c 00   A  0   0  1
  [ 2] .note.gnu.property NOTE            0000000000000338 000338 000020 00   A  0   0  8
  [ 3] .note.gnu.build-id NOTE            0000000000000358 000358 000024 00   A  0   0  4
  [ 4] .note.ABI-tag     NOTE            000000000000037c 00037c 000020 00   A  0   0  4
  [ 5] .gnu.hash         GNU_HASH        00000000000003a0 0003a0 000024 00   A  6   0  8
  [ 6] .dynsym           DYNSYM          00000000000003c8 0003c8 0000a8 18   A  7   1  8
  [ 7] .dynstr           STRTAB          0000000000000470 000470 000082 00   A  0   0  1
  [ 8] .gnu.version      VERSYM          00000000000004f2 0004f2 00000e 02   A  6   0  2
  [ 9] .gnu.version_r    VERNEED         0000000000000500 000500 000020 00   A  7   1  8
  [10] .rela.dyn         RELA            0000000000000520 000520 0000c0 18   A  6   0  8
  [11] .rela.plt         RELA            00000000000005e0 0005e0 000018 18  AI  6  24  8
  [12] .init             PROGBITS        0000000000001000 001000 00001b 00  AX  0   0  4
  [13] .plt              PROGBITS        0000000000001020 001020 000020 10  AX  0   0 16
  [14] .plt.got          PROGBITS        0000000000001040 001040 000010 10  AX  0   0 16
  [15] .plt.sec          PROGBITS        0000000000001050 001050 000010 10  AX  0   0 16
  [16] .text             PROGBITS        0000000000001060 001060 000185 00  AX  0   0 16
  [17] .fini             PROGBITS        00000000000011e8 0011e8 00000d 00  AX  0   0  4
  [18] .rodata           PROGBITS        0000000000002000 002000 000010 00   A  0   0  4
  [19] .eh_frame_hdr     PROGBITS        0000000000002010 002010 000044 00   A  0   0  4
  [20] .eh_frame         PROGBITS        0000000000002058 002058 000108 00   A  0   0  8
  [21] .init_array       INIT_ARRAY      0000000000003db8 002db8 000008 08  WA  0   0  8
  [22] .fini_array       FINI_ARRAY      0000000000003dc0 002dc0 000008 08  WA  0   0  8
  [23] .dynamic          DYNAMIC         0000000000003dc8 002dc8 0001f0 10  WA  7   0  8
  [24] .got              PROGBITS        0000000000003fb8 002fb8 000048 08  WA  0   0  8
  [25] .data             PROGBITS        0000000000004000 003000 000010 00  WA  0   0  8
  [26] .bss              NOBITS          0000000000004010 003010 000008 00  WA  0   0  1
  [27] .comment          PROGBITS        0000000000000000 003010 00002b 01  MS  0   0  1
  [28] .symtab           SYMTAB          0000000000000000 003040 000618 18     29  46  8
  [29] .strtab           STRTAB          0000000000000000 003658 000203 00      0   0  1
  [30] .shstrtab         STRTAB          0000000000000000 00385b 00011a 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  l (large), p (processor specific)
```
* The view of the ELF the linker uses
* Is a table composed of sections
* Address is virt addr when exe is loaded, offset is where this section is located within ELF file
* Table reserves certains parts of memory to be used in various ways
* Below we look at every section, what it does, and what its contents are in this program.

| Section | Description | Value | 
| --- | --- | --- |
| *NULL* | First section is always null section | - |
| .interp | Contains C string of location of dynamic linker | /lib64/ld-linux-x86-64.so.2 |
| .note.gnu.property | Meta Data Note | x86 feature IBT and SHSTK |
| .note.gnu.build-id | Meta Data Note | Build ID 0d098f5807214fb4a10978181b153fcb7b09af2a |
| .note.ABI-tag | Meta Data Note | OS: Linux, ABI: 3.2.0 |
| .gnu.hash | Hash table for looking up symbols in smbol table | - |
| .dynsym | Dynamic Symbols to be resolved during runtime linking | - |
| .dynstr | ASCII strings of names of symbols in dyamic symbol table | libc.so.6, puts, __cxa_finalize, __libc_start_main, GLIBC_2.2.5, _ITM_deregisterTMCloneTable, __gmon_start__, _ITM_registerTMCloneTable |
| .gnu.version | Meta Data on GNU Version | GLIBC 2.2.5 |
| .gnu.version_r | Versioning see [4] | - |
| .rela.dyn | Relocation table for fixup of dynamic symbols | - |
| .rela.plt | Relocation table for the fixup of dynamic functions | puts@GLIBC_2.2.5 |
| .init | Code section to call gprof init if flag set in complier (and possibly other init code to be ran prior to entry of program) | Run `objdump -d hello` | 
| .plt | Code section for Procedural Linkage Table. Involved in Dynamic Linking | Run `objdump -d hello` |
| .plt.got | Code section for PLT Global Offset table. Involved in Dynamic Linking | Run `objdump -d hello` |
| .plt.sec | Code section involved in dynamic linking | Contains the defintion of <puts@plt> |
| .text | Code section that contains users compiled assembly. Also contains severs compiler inserted functions  | _start, deregister_tm_clones, register_tm_clones, __do_global_dtors_aux, frame_dummy, main, __libc_csu_init, __libc_csu_fini |
| .fini | Code section for termination code | _fini code, appears to be empty boiler plate |
| .rodata | Contains all string literals | "Hello World" |
| .eh_frame_hdr | Header for exeption handling frames (CFI) | - |
| .eh_frame | Section for frame data | - |
| .init_array | Array of function pointers that are executed prior to exection of main. Mark these functions w/ `__attribute__((constructor(PRIO)))` where PRIO is priorty > 100 | 0x1140 (frame dummy) |
| .fini_array | Array of function pointers that are executed upon proper exit of main | 0x1100 (__do_global_dtors_aux) |
| .dynamic | Used in dynamic linking | `readelf -d hello` |
| .got | Global Offset Table, addresses of global variables and functions | 0x3dc8 (points to .dynamic in mem)|
| .data | Inialized Global variables are defined here | none | __data_start, __dso_handle | 
| .bss | Uninitialized data of program | Not actually stored on disk in ELF file, only exists when loaded into memory |
| .comment | GCC and OS metadata | GCC 9.4.0, Ubuntu 20.04.1 |
| .symtab | Appears to store all the "important" things location in memory | `readelf -s hello` |
| strtab | Stores the strings associated with the entries in the symtable (static only) | `readelf -p .strtab hello` |
| .shstrtab | String table for section names | `readelf -p .shstrtab hello` | 

## Program Header:
```
$ readelf -l --wide hello

Elf file type is DYN (Shared object file)
Entry point 0x1060
There are 13 program headers, starting at offset 64

Program Headers:
  Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
  PHDR           0x000040 0x0000000000000040 0x0000000000000040 0x0002d8 0x0002d8 R   0x8
  INTERP         0x000318 0x0000000000000318 0x0000000000000318 0x00001c 0x00001c R   0x1
      [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
  LOAD           0x000000 0x0000000000000000 0x0000000000000000 0x0005f8 0x0005f8 R   0x1000
  LOAD           0x001000 0x0000000000001000 0x0000000000001000 0x0001f5 0x0001f5 R E 0x1000
  LOAD           0x002000 0x0000000000002000 0x0000000000002000 0x000160 0x000160 R   0x1000
  LOAD           0x002db8 0x0000000000003db8 0x0000000000003db8 0x000258 0x000260 RW  0x1000
  DYNAMIC        0x002dc8 0x0000000000003dc8 0x0000000000003dc8 0x0001f0 0x0001f0 RW  0x8
  NOTE           0x000338 0x0000000000000338 0x0000000000000338 0x000020 0x000020 R   0x8
  NOTE           0x000358 0x0000000000000358 0x0000000000000358 0x000044 0x000044 R   0x4
  GNU_PROPERTY   0x000338 0x0000000000000338 0x0000000000000338 0x000020 0x000020 R   0x8
  GNU_EH_FRAME   0x002010 0x0000000000002010 0x0000000000002010 0x000044 0x000044 R   0x4
  GNU_STACK      0x000000 0x0000000000000000 0x0000000000000000 0x000000 0x000000 RW  0x10
  GNU_RELRO      0x002db8 0x0000000000003db8 0x0000000000003db8 0x000248 0x000248 R   0x1

 Section to Segment mapping:
  Segment Sections...
   00     
   01     .interp 
   02     .interp .note.gnu.property .note.gnu.build-id .note.ABI-tag .gnu.hash .dynsym .dynstr .gnu.version .gnu.version_r .rela.dyn .rela.plt 
   03     .init .plt .plt.got .plt.sec .text .fini 
   04     .rodata .eh_frame_hdr .eh_frame 
   05     .init_array .fini_array .dynamic .got .data .bss 
   06     .dynamic 
   07     .note.gnu.property 
   08     .note.gnu.build-id .note.ABI-tag 
   09     .note.gnu.property 
   10     .eh_frame_hdr 
   11     
   12     .init_array .fini_array .dynamic .got 

```
* The view when loading an executable into memory.
* Table of segments
    * Which themselves are composed of sections.
* Appears to describe program layout in memory.
* Most important take away is the mapping of sections into segments to be loaded into memory
    * Believe this is dictated by linker scripts

## Exercise, Where the F**k is Waldo?

Goal of this exercise is to write C code that can explore some of the things stored in memory mentioned above. Will put this in `ph_exp.c`. Use output of this program, readelf and objdump to get an idea of where these sectons fall into program memory, relative to the stack and heap.

```C
// Program to explore its own org in memory.

#include <stdio.h>
#include <stdlib.h>

int gbl_uninit;
int gbl_init = 0;
char* gbl_str = "GBL";

__attribute__((constructor(101))) void init_func1(void)
{
    printf("Starting...\n");
    return;
}

int func1(int x)
{
    return x+1;
}

int main(void) 
{
    unsigned char dummy = 0;
    char* local_str = "LCL";
    unsigned char* main_frame_stack_pos = &dummy;
    unsigned char* heap_start_pos = malloc(0x1000);

    printf("Main Frame Stack Pos = %p\n", main_frame_stack_pos);                // Top of address space (from main frame perspective)
    printf("malloc rela Pos      = %p\n", (unsigned char*) malloc);
    printf("printf rela Pos      = %p\n", (unsigned char*) printf);
    printf("Heap Start Pos       = %p\n", heap_start_pos);                      // ??
    printf("Un-Init Gobal Pos    = %p\n", (unsigned char*) &gbl_uninit);        // .bss
    printf("Init Gobal Pos       = %p\n", (unsigned char*) &gbl_init);          // .data
    printf("Local String Pos     = %p\n", (unsigned char*) local_str);          // .rodata +4
    printf("Global String Pos    = %p\n", (unsigned char*) gbl_str);            // .rodata
    printf("main Pos             = %p\n", (unsigned char*) main);               // .text + ?? + len(func1)
    printf("func1 Pos            = %p\n", (unsigned char*) func1);              // .text + ??
    printf("init_func1 Pos       = %p\n", (unsigned char*) init_func1);         // .text
    return 0;
}
```

```
$ ./ph
Starting...
Main Frame Stack Pos = 0x7ffe427dff7f
malloc rela Pos      = 0x7fdf4bb940e0
printf rela Pos      = 0x7fdf4bb5bc90
Heap Start Pos       = 0x55c0cb2446b0
Un-Init Gobal Pos    = 0x55c0ca703020
Init Gobal Pos       = 0x55c0ca70301c
Local String Pos     = 0x55c0ca70100d
Global String Pos    = 0x55c0ca701004
main Pos             = 0x55c0ca7001b3
func1 Pos            = 0x55c0ca7001a0
init_func1 Pos       = 0x55c0ca700189
```

## Questions

### Linking Questions
* **Q** How are all these sections used in linking?
* **Q** Interpeter `/lib64/ld-linux-x86-64.so.2`??
    * **A** This is the dynamic linker and is present in all shared library object files. When the program is ran, both this elf and `hello` are loaded into memory. Execution is first passed to the dynamic linker that resolves undefined symbols and handles linking shared libraries.

#### PLT and GOT
* **Q** Does every dynamically linked function get an entry in .plt.sec?
* **Q** plt.got vs got?
* **Q** When is the .plt, .plt.got and .plgt code section called?

#### EH frames and section
* **Q** In Section header, addr and off match up until eh_frame, why?
* **Q** Why Does eh frame get mapped to 2 sections (linker scripts)?
* **Q** Can we look at these EH frames, CFI?
* **Q** Unwinding Problem?
* **Q** eh section loaded RO? How do we push CFI to it.

#### Symbols
* **Q** dso_handle?
* **Q** What exactly are these entries in the symbol table?
* **Q** What does compiling with debug symbols do to the output?
* **Q** What are all the functions in the .text section?

### Program Headers Questions
* **Q** In program header why is virt addr and phys addr the same?
    * **A** phys addr is important only in embedded systems without a virt memory system.
* **Q** Where are the stack and heap relative to the program headers?
    * **A** See exercise above.
* **Q** Why are several section mapped multiple times to segments?
    * **A** Appears as though a section only appears twice if one of those occurances is in a load segment. Thus it would make sense that some sections would be assigned twice if it needs to be in a memory and a non load section.
* **Q** In program header why is GNU stack mem size 0?
    * **A** the GNU stack is a stack extension and space is only allocated if this is needed.

### Random Questions
* **Q** When I run `./hello` how does it know read ELF header and process it accordingly.
    * **A** ELF file formats defined at `/usr/include/elf.h`
* **Q** What exactly happens when I run `./hello`.
    * **A** Program execution will be covered in future topic
* **Q** How does it determine entry point?
    * **A** Matches with offset of .text. This must be where actual machine code of program is stored within ELF.
* **Q** GNU Hash?
    * **A** Hashtable to speed up symbol table look up
* **Q** Why is printf not in .dynstr?
    * **A** Compiler optimizes this to puts which is a function for putting a string on STDOUT
* **Q** What is __gmon_start and what is it called in .init?
    * **A** Appears to be an init function pointer symbol for a profiling tool, gprof. If compiled with the profiling flags on, this will be called prior to entry into the main prog.
* **Q** `bnd jmpq` and `endbrk` instructions?
    * **A** BND is an intrsuction prefix making use of intel MPX indicating to check target branch against register stored bounds. The endbr64 is described here https://stackoverflow.com/questions/56905811/what-does-the-endbr64-instruction-actually-do. 
* **Q** Are their limits to what kind of code can be called in these init, fini and pre init sections? How can this be used?
    * **A** In both the init and fini sections code has access too dynamically linked libaries. Can be used as constructor and destructors.


## Resources
* [1] https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
* [2] https://github.com/compilepeace/BINARY_DISSECTION_COURSE/blob/master/ELF/ELF.md
* [3] https://lwn.net/Articles/631631/
* [4] https://refspecs.linuxfoundation.org/LSB_3.0.0/LSB-PDA/LSB-PDA.junk/symversion.html

# Process Start Up

![alt text](callgraph.png)

## Resources

* [10] http://dbp-consulting.com/tutorials/debugging/linuxProgramStartup.html