# Hello World, A link to the past

In this installment we will examine the process of STATIC linking. In [hello world](../Hello_World/) we looked at the contents and format of an executable. Many of the contents of an executable are reserved for the process of linking. Thus linking is a natural second topic. We will first look at the process by which a .c file is turned into an elf, then we will look at the symbol table and how symbols are resolved. And finally we will look at how the location of input object files are combined to create the end executable. The end goal here is first to obviously understand this process, but secondly to answer our unanswered questions from the previous exercise. 

To highlight the process of linking we slightly complicated the classic hello world. We now have two C files, a library containting the "hello world" string as global and accesed through an accesor function. The main entry point is contained in `exe.c` and this accesor is contained in `lib.c`.

## What exactly is GCC doing?

In order to fully understand linking, the reader should be aware that when we call `gcc` it produces an exe through several stages, each of which are seperate command line tools. These are Preprocessing (cpp) -> Compiler (cc) -> Assembling (as) -> Linking (ld). In this section we give a brief overview of exactly what happens when going from a `.c` to an ELF file that can be linked or executed.

### Preprocessing
Preprocessing outside the scope of this project, but this is the stage where preprocessor macros are evaluated.

Input)
```C
#define STRING "Hello"
char* string_ptr = STRING;

char* get_str() {
  return string_ptr;
}
```

Output `cpp lib.c ./lib.i`)
```C
# 1 "lib.c"
# 1 "<built-in>"
# 1 "<command-line>"
# 31 "<command-line>"
# 1 "/usr/include/stdc-predef.h" 1 3 4
# 32 "<command-line>" 2
# 1 "lib.c"

char* string_ptr = "Hello";

char* get_str(int x) {
    return string_ptr;
}

```

The meaning of the directives at the top will be left for a later study and can be further researched [here](https://gcc.gnu.org/onlinedocs/cpp/Preprocessor-Output.html). The key take away here is that the preprocessor macro `STRING` has been evaluated based on its definition in the same file and the code file that actually gets compiled has a string literal in place of the macro.

### Compiling

Compilation is the process of turning C into assembly source code. Again a detailed investigation is outside of our current scope, but as we will see several artifacts that are used in linking appear first in the assembly output. The input file is the `lib.i` intermediate file shown above and the output is the result of `cc -S lib.i`)

```assembly
	.file	"lib.c"             ; Create file type symbol table entry w/ name "lib.c"
	.text                       ; Make current active section .text
	.globl	string_ptr          ; Add "string_ptr" to symbol table as global
	.section	.rodata         ; Make and switch to .rodata section
.LC0:
	.string	"Hello"                   ; Place string literal into object at cur loc
	.section	.data.rel.local,"aw"  ; Define non reserved section with flags
	.align 8
	.type	string_ptr, @object       ; Sets symbol type to object (data)
	.size	string_ptr, 8             ; Sets symbol size
string_ptr:
	.quad	.LC0                      ; Allocate space object for pointer
	.text                             ; Switch to .text section
	.globl	get_str                   ; Add "get_str" to symbol table as global
	.type	get_str, @function        ; Define type to be function
get_str:                              ; Assebly of function entry point
.LFB0:
	.cfi_startproc
	endbr64                           ; Mark this locale as suitable for call
	pushq	%rbp                      ; Push Old stack frame base ptr 
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp                ; Set new stack frame base ptr
	.cfi_def_cfa_register 6
	movq	string_ptr(%rip), %rax    ; Copy "place holder" addr of string into ret reg
	popq	%rbp                      ; Restore old stack base pointer
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	get_str, .-get_str        ; Set size of get_str sybol
	.ident	"GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0" ; Add comment to .coomment section
	.section	.note.GNU-stack,"",@progbits   ; Create section
	.section	.note.gnu.property,"a"         ; Create section
	.align 8
	.long	 1f - 0f                           ; from here on below, add gnu property meta data
	.long	 4f - 1f
	.long	 5
0:
	.string	 "GNU"
1:
	.align 8
	.long	 0xc0000002
	.long	 3f - 2f
2:
	.long	 0x3
3:
	.align 8
4:

```

After compilation proper, we see a resemblance to an ELF file explored previously. Sections start to appear such as .text (compiled user code) and .rodata (string literals). It appears as though the `.LC0, .LFB0, and .LFE0` are compiler "local variables" that do not survive assembly. Also the .cfi directives are used in exception handling and outside our current scope. Regardless we can see two important things here. First data, funtions, and meta data are organized into sections via the `.section` directive. Second, we now have compiled aseembly instead of C code. Running through the above assembly we can see that we get a "recipe" for constructing our final ELF.

* [x86 ref](https://docs.oracle.com/cd/E26502_01/html/E28388/eoiyg.html)

### Assembling

Assembling creates the ELF output we are familiar with. The assembler is invoked via `as lib.s -o lib.o`. Execute `readelf -a lib.o --wide `)

```
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              REL (Relocatable file)
  Machine:                           Advanced Micro Devices X86-64
  Version:                           0x1
  Entry point address:               0x0
  Start of program headers:          0 (bytes into file)
  Start of section headers:          792 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           0 (bytes)
  Number of program headers:         0
  Size of section headers:           64 (bytes)
  Number of section headers:         16
  Section header string table index: 15

Section Headers:
  [Nr] Name              Type            Address          Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            0000000000000000 000000 000000 00      0   0  0
  [ 1] .text             PROGBITS        0000000000000000 000040 000011 00  AX  0   0  1
  [ 2] .rela.text        RELA            0000000000000000 000240 000018 18   I 13   1  8
  [ 3] .data             PROGBITS        0000000000000000 000051 000000 00  WA  0   0  1
  [ 4] .bss              NOBITS          0000000000000000 000051 000000 00  WA  0   0  1
  [ 5] .rodata           PROGBITS        0000000000000000 000051 000006 00   A  0   0  1
  [ 6] .data.rel.local   PROGBITS        0000000000000000 000058 000008 00  WA  0   0  8
  [ 7] .rela.data.rel.local RELA            0000000000000000 000258 000018 18   I 13   6  8
  [ 8] .comment          PROGBITS        0000000000000000 000060 00002c 01  MS  0   0  1
  [ 9] .note.GNU-stack   PROGBITS        0000000000000000 00008c 000000 00      0   0  1
  [10] .note.gnu.property NOTE            0000000000000000 000090 000020 00   A  0   0  8
  [11] .eh_frame         PROGBITS        0000000000000000 0000b0 000038 00   A  0   0  8
  [12] .rela.eh_frame    RELA            0000000000000000 000270 000018 18   I 13  11  8
  [13] .symtab           SYMTAB          0000000000000000 0000e8 000138 18     14  11  8
  [14] .strtab           STRTAB          0000000000000000 000220 00001a 00      0   0  1
  [15] .shstrtab         STRTAB          0000000000000000 000288 000089 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  l (large), p (processor specific)

There are no section groups in this file.

There are no program headers in this file.

There is no dynamic section in this file.

Relocation section '.rela.text' at offset 0x240 contains 1 entry:
    Offset             Info             Type               Symbol's Value  Symbol's Name + Addend
000000000000000b  0000000b00000002 R_X86_64_PC32          0000000000000000 string_ptr - 4

Relocation section '.rela.data.rel.local' at offset 0x258 contains 1 entry:
    Offset             Info             Type               Symbol's Value  Symbol's Name + Addend
0000000000000000  0000000500000001 R_X86_64_64            0000000000000000 .rodata + 0

Relocation section '.rela.eh_frame' at offset 0x270 contains 1 entry:
    Offset             Info             Type               Symbol's Value  Symbol's Name + Addend
0000000000000020  0000000200000002 R_X86_64_PC32          0000000000000000 .text + 0

The decoding of unwind sections for machine type Advanced Micro Devices X86-64 is not currently supported.

Symbol table '.symtab' contains 13 entries:
   Num:    Value          Size Type    Bind   Vis      Ndx Name
     0: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 0000000000000000     0 FILE    LOCAL  DEFAULT  ABS lib.c
     2: 0000000000000000     0 SECTION LOCAL  DEFAULT    1 
     3: 0000000000000000     0 SECTION LOCAL  DEFAULT    3 
     4: 0000000000000000     0 SECTION LOCAL  DEFAULT    4 
     5: 0000000000000000     0 SECTION LOCAL  DEFAULT    5 
     6: 0000000000000000     0 SECTION LOCAL  DEFAULT    6 
     7: 0000000000000000     0 SECTION LOCAL  DEFAULT    9 
     8: 0000000000000000     0 SECTION LOCAL  DEFAULT   10 
     9: 0000000000000000     0 SECTION LOCAL  DEFAULT   11 
    10: 0000000000000000     0 SECTION LOCAL  DEFAULT    8 
    11: 0000000000000000     8 OBJECT  GLOBAL DEFAULT    6 string_ptr
    12: 0000000000000000    17 FUNC    GLOBAL DEFAULT    1 get_str

No version information found in this file.

Displaying notes found in: .note.gnu.property
  Owner                Data size 	Description
  GNU                  0x00000010	NT_GNU_PROPERTY_TYPE_0	      Properties: x86 feature: IBT, SHSTK

```

* We an see from the above ELF dump that it is much simplier than the hello world ELF
* It pretty much only contains the code and meta data
* It contains no information on how to map any of the code or data sections into memory
    * No program headers
* Note the type is a relocatable file (hello world was a shared object file), which is essentially assembled code with no program headers.
* **Q** x86 feature: IBT, SHSTK?
* **Q** OLD QUESTION, eh frames?

## Symbols, What could they mean? (BONUS C Keywords!!!)

The assembly output of the compiler gave us the recipe for building a relocatable ELF file as shown above. The recipe defined sections, symbols, global data, and compiled code. Data and compiled code are straight forward. Sections were covered in the previous hello world investigation. So in this section we look at symbols and the symbol table.

### Globals, Locals, Externs, Functions and their symbols

Below we craft a C file to exemplify how various global variables, functions, and certain keywords affect the contents of the symbol table. This is compiled with `gcc -c sym_0.c`. Then we include the generated symbol table below that.

```C
extern int undef_sym;

int global_init = 1;
int global_uninit;

static int static_global_init =1;
static int static_global_uninit;

int f1()
{
    return 0;
}

int main() {
    int local = 0;
    static int static_local = 1;

    local = undef_sym;
}
```

```
$ readelf -s sym_0.o

Symbol table '.symtab' contains 17 entries:
   Num:    Value          Size Type    Bind   Vis      Ndx Name
     0: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT  UND 
     1: 0000000000000000     0 FILE    LOCAL  DEFAULT  ABS sym_0.c
     2: 0000000000000000     0 SECTION LOCAL  DEFAULT    1 
     3: 0000000000000000     0 SECTION LOCAL  DEFAULT    3 
     4: 0000000000000000     0 SECTION LOCAL  DEFAULT    4 
     5: 0000000000000004     4 OBJECT  LOCAL  DEFAULT    3 static_global_init
     6: 0000000000000000     4 OBJECT  LOCAL  DEFAULT    4 static_global_uninit
     7: 0000000000000008     4 OBJECT  LOCAL  DEFAULT    3 static_local.1920
     8: 0000000000000000     0 SECTION LOCAL  DEFAULT    6 
     9: 0000000000000000     0 SECTION LOCAL  DEFAULT    7 
    10: 0000000000000000     0 SECTION LOCAL  DEFAULT    8 
    11: 0000000000000000     0 SECTION LOCAL  DEFAULT    5 
    12: 0000000000000000     4 OBJECT  GLOBAL DEFAULT    3 global_init
    13: 0000000000000004     4 OBJECT  GLOBAL DEFAULT  COM global_uninit
    14: 0000000000000000    15 FUNC    GLOBAL DEFAULT    1 f1
    15: 000000000000000f    31 FUNC    GLOBAL DEFAULT    1 main
    16: 0000000000000000     0 NOTYPE  GLOBAL DEFAULT  UND undef_sym
```

The first thing to note is that local variables do not populate into the symbol table. An `objdump` of `sym_0.o` shows that local variables are implemented by allocating stack space. Thus when on encounters a local statement `int x = 0;`, one should take this as telling the compiler to allocated 4 bytes on the stack and assign 0 to it.

Next let us discuss what exactly a symbol table entry consists of and what a symbol table does at a high level. Below is the definition of a symbol table entry. The symbol table keeps track of all "symbols" defined in a file, their location within their respective section, their scope i.e. binding i.e. local vs global and finally the symbol's type (function and data, etc). To motivate why this must exist, consider our current hello world example. `exe.c` calls a function from `lib.c` to get a string to print. Now, each of these files are compiled seperately as they are different files and thus produce different ELF files each with their own sections. Thus in `exe.c` there is a reference to a function not defined. It'd be nice if somewhere in `exe.o` there was something to say "hey we got a function but don't know where to go to find it yet." Better yet, it'd be nice if in `lib.o` there was something saying "hey to anyone referncing this function we have it for you at this offset within this section of my ELF." This is one of the funcions of the symbol table.

```C
typedef struct
{
  Elf64_Word	st_name;		/* Symbol name (string tbl index) */
  unsigned char	st_info;		/* Symbol type and binding */
  unsigned char st_other;		/* Symbol visibility */
  Elf64_Section	st_shndx;		/* Section index */
  Elf64_Addr	st_value;		/* Symbol value (section offset of phys addr)*/
  Elf64_Xword	st_size;		/* Symbol size */
} Elf64_Sym;
```

Returning to our `sym_0.c` file we can make a few comments.
* Global Varibales declared `extern` (`undef_sym`) get put in the psudeo section UND to let the linker know this reference is defined else where. If at the end of the linking process there remains any undefined symbols then it throws an error.
* Inited global variables (`global_init`) get placed in the .data section and have a global binding indicating other files can freely reference these variables.
* Uninited global vaiables (`global_uninit`) gets placed in a psdeuo section COM i.e. COMMON. This section is not actually phsically present, instead it let's the linker know that we have an uninited global variable. The linker will place this in the .bss section of the final executable but will throw an error if it finds an inited symbol of the same name.
* Static inited global variables (`static_global_init`) get placed in the .data section. Note the value of this entry is 4 b/c this is the offset within the .data section one find this variable. Also note the LOCAL binding indicating this variables scope is limited to this file.
* Static uninited global variables (`static_global_uninit`) get placed in the .bss section.
* Functions get placed in the .text section.
* Local static variables will get placed in .data or .bss based on inited or not. But key thing is that the compiler adds a postfix to the symbol name to make it unique. This is because two functions in the same file could use the same local static variable name, but these two variables do not refer to the same data.
* Final point of clarification, the string table index stored in the symbol table entry indexed the .strtab section. The .shstrtab is the string table indexed by section table entries.
* **Q** ABS?
* **Q** Why are some sections added to symbol table?
* **Q** Why are some files added to the symbol table


### Symbol Resolution

Global Symbol Resolution Rules)
* Functions and inited global variables cannot have two defintions
* References of uninited global variables will be resolved to an inited global variable of the same name if it exists.
* Two uninted global variables, either symbol is used.

Static Libraries)
* A static library is just a concatenation of relocatable object files
* Use `ar` command line tool to create them from a colection of .o files
* Allows one to have a collection of smaller relocatable files such that references to symbols in the static library do not add the entire library, just the relocatable file from which the symbol is in.

Ordering Matters)
* Suppose we pass the linker a set of input files and archives.
* The linker will link these files into a single elf using the following process

* Let $E$ be set of relocatable files to be added to final elf
* Let $U$ be set of undefined symbols
* Let $D$ be set of defined symbols
* For each file $f$:
  * If $f$ is single relocatable:
    * Add $f$ to $E$
    * Update set of defined symbols from $f$ into $D$
    * Update set of undefined symbols from $f$ into $U$
  * If $f$ is archive:
    * While change occur in $E$, $D$, or $U$:
      * For each relocatable object $m$ in $f$:
        * If $m$ defines symbol needed currently in $U$:
          * Add $m$ to $E$
          * Update $U$ and $D$

Essentially the above routine does a linear scan of all files passed to the linker. If its a single relocatable, add its symbols and relocatble file contents to the output, updating undefined symbols as we find them in future files. If its a archive file, keep looping over the relocatable modules found in the archive until there is no change. At the end if their remains any undefined symbols then throw an error, otherwise no error.

From this we can gather 2 important details in linking. 1) the ordering within a archive does not affect the output but may affect the time it takes to link. 2) and most importantly, the order of the files sent to the linker matter. If file `a.o` refences symbols in `b.o`, `b.o` must come after `a.o` on the file input array to the linker.

Finally there is a notion of weak bindings that is discussed [here](https://docs.oracle.com/cd/E19683-01/816-1386/chapter2-11/index.html). The purpose of weak binding is so that we can reference symbols that may or may not be included in the final exe without introducing compiler errors.

### Other C Keywords and addendums

* switch statements
  * `switch.c`
* what about struct or enum definitions?
  * implicitly harded coded by compiled assembly, no symbol table entries
* debug symbols -g section
  * adds a whole lot of sections. Seems like a bit of a rabit whole.
* Beware of impicit return type assumption of undefined functions (w/o signature). Erase the signature of `get_str` in `exe.c` and compare the assembly. HINT: `cltq`.s

## Relocation

In the previous section we looked at the symbol table and some rules the linker uses to resolve symbols. In this section we shall explore relocation, which is the step the linker must take to 1) merge object files into a single executable and 2) references in code to symbols with the proper location of those symbols final resting location in the executable.

To explore this let us look at our complicated hello world with a few extras to exempify this process. Below is `exe.c` containing the hello world code and `lib.c` is mini library it access which was explored in the above sections.

```C
#include <stdio.h>

int exe_gbl = 7;

// lib.c references
char* get_str();
extern int lib_gbl;

int main(int argc, char** argv) {
    puts(get_str());

    int ref1 = exe_gbl;
    int ref2 = lib_gbl;
    int ref3 = exe_gbl;

    return 0;
}
```

This hello world accesses a static (private) string from `lib.c` via its defined accessor and then for demonstration purposes access its global and a global from `lib.c`. References to symbols are populated in the relocation table i.e. the sections of type "RELA". We compile this code with `gcc -c exe.c` and output the relocation table data with `readelf -r exe.o`.

```
Relocation section '.rela.text' at offset 0x2b8 contains 5 entries:
  Offset          Info           Type           Sym. Value    Sym. Name + Addend
000000000019  000c00000004 R_X86_64_PLT32    0000000000000000 get_str - 4
000000000021  000d00000004 R_X86_64_PLT32    0000000000000000 puts - 4
000000000027  000900000002 R_X86_64_PC32     0000000000000000 exe_gbl - 4
000000000030  000e00000002 R_X86_64_PC32     0000000000000000 lib_gbl - 4
000000000039  000900000002 R_X86_64_PC32     0000000000000000 exe_gbl - 4

Relocation section '.rela.eh_frame' at offset 0x330 contains 1 entry:
  Offset          Info           Type           Sym. Value    Sym. Name + Addend
000000000020  000200000002 R_X86_64_PC32     0000000000000000 .text + 0
```

We will ignore the `rela.eh_frame` section for now and focus on the `rela.txt` section. As we can see every reference to a symbol gets an entry even if its referencing the same symbol twice. For now let us focus on the 3 global references. First thing to note is "Offset" points to the bytes within the instructuion to replace with the final location of the symbol. The info field contains the symbol table index in the top 4 bytes and the type in the lower. For these global references the type of relocation is a 32bit intruction relative pointer. Meaning the location will be relative to the intruction pointer value when it is executing the intruction containing the symbol reference. To make this concrete, lets look at the byte code for the first `exe_gbl` reference.

```
25:	8b 05 00 00 00 00    	mov    0x0(%rip),%eax        # 2b <main+0x2b>
```

The above is a mem to register mov indicated by the 0x8b opcode. The second byte is called a ModR/M ([see here](https://www.cs.uaf.edu/2016/fall/cs301/lecture/09_28_machinecode.html)). 0x05 indicates the next 4 bytes are an offset of %RIP and move into EAX. One thing to note as mentined above is the offset stored in the relocation table points to the 4 byte RIP relative address it needs to fill in. 

Next let us turn our attention to the fully linked executable `exe`. The final PC relative instruction is the following:

```
116e:	8b 05 9c 2e 00 00    	mov    0x2e9c(%rip),%eax        # 4010 <exe_gbl>
```

But how did it compute this? First off by examining `exe` we can see that the .data sections of the two input object files have been merged and have runtime address. Thus our target symbol has a runtime address. Also the .text sections of the object files have been merged into one and we have an offset into the orginal `exe.o` .text section where are symbol reference resides. With all this we can compute the offset placed in the assembly code above. Let $S$ be the runtime address of the symbol after it is merged. Let $O$ be the offset of the symbol reference which comes from the relocation table. Let $L$ be the runtime address of where the `exe.o` .text section got loaded. So our final PC relative address $A$ is $A=S-(L+O)$. We can disasemble the final `exe` to get these values.

* $S=0x4010$
* $O=0x27$
* $L=0x1149$
* So, $A=0x2EA0$?

But in the assembly code we see the actual address $0x2E9C$. Howeve there is one cavet. We need to add the "Addend" parameter found in relocation table entry. Since the instruction pointer points to the next instruction and the next instruction is 4 bytes after our 32bit PC relative address, we need to subtract 4 bytes from $A$ to get the correct address to substitute.

Thus we have shown the basics of relocation. 1) merge all appropiate symbols and 2) replace all refences to symbols found in the relocation table with their merged locations. However, we skipped over the two function relocation table entries, which brings us to our next topic the PLT or Procedural Linkage Table.

## Exercise, Create a Minimal Hello World

To be rigorious the goal is to minimize the ELF size of the final executable, while still writing the string "Hello World" to the terminal.

**Solution**

```
.section .text
.globl _start
_start:
    mov $4, %eax
    mov $1, %ebx
    mov $msg, %ecx
    mov $12, %edx
    int $0x80
    mov $1, %eax
    int $0x80

.section .data
msg:
    .ascii "Hello World\n"
```

Compile with `as min_hello.S -o min_hello.o && ld -o min_hello min_hello.o -s -n -N --verbose`. 

`min_hello` layout)
* 0x00 to 0x040  ->  ELF64 Header. Fixed Header Size
* 0x40 to 0x078  ->  Program Headers. Singular Program header of 0x38 bytes.
* 0x78 to 0x095  -> .text section. Write Syscall takes 3 args and calling `int` instruction requires another arg. We also call exit which may or may not be required. Assuming it is, this is a minimal instruction set to accomplish "hello world" from user space using syscall.
* 0xa1 to 0x0b8  ->  .shstrtab must be included
* 0xb8 to 0x1b8  ->  section headers. 4 Sections at 64 bytes

From the above layout we get an over alls size of 0x1b8 bytes or 440 bytes which is just about the smallest valid hello world ELF that one could craft. We could maybe trim the .shstrtab, the exit sys call, and we could use the ELF32 standard to trim a few bytes. However, this is minimal given certain reasonable constraints.

We will go over interrupts and systemcalls in more detail later. However, the [resource](https://www.tutorialspoint.com/assembly_programming/assembly_system_calls.htm) has some good info on how the system call write was used above.

## Resources

* [1] [CSAPP](../Computer%20Systems%20A%20Programmers%20Perspective%20(3rd).pdf)(Chapter 7)
