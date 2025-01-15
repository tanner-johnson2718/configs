// ================================ lazy.c ====================================
// The goal here is to look at the process of lazy binding. We want look at
// the GOT and see where a library call points to, prior to calling that func.
// Call that library function. Then look at the GOT again and see its updated
// pointer. We constrain ourselves such that we cannot and use the C stdlb,
// nor can we use absolute addressing. I.e. it must compile with
// "-nostdlib -fPIC".
// ============================================================================

// ============================================================================
// Headers, Macros, and Forward Declarations
// ============================================================================

// Create macros cause 1 nobody wants to type unsigned. 2 make it explicit 
// what data type your using. "long" means nothing. "u64" tells me unsigned
// 64bit value.
#define u64 unsigned long
#define u32 unsigned int

// Macros to toggle helper function test driver code.
#define TEST_VAL_TO_ASCII 0
#define TEST_PTR_TO_HEX_STR 0

void my_puts(char* str, long len);
void inc_counter();

// ============================================================================
// String Manip
// ============================================================================

// Take in a u64 and convert it to its ascii value.
char val_to_ascii(u64 in)
{
    if(in < 10ul)
    {
        return (char) (in + 48ul);     // 48 = ascii('0')
    }

    // 97 = ascii('a'). Subtract 10 so that 10 -> 'a'.
    return (char) (in -10ul + 97ul);          
}

// Assume out is char buff with enough room for out str. Convert the ptr to
// a hex ascii string. Return number of byte written.
u32 ptr_to_hex_str(u64 ptr, char* out)
{

    u64 temp[16];
    u32 ctr = 0;

    // Mod it 16 to find lowest digit. Divide by 16 then mod again to find next
    // lowest digit. Loop this until we get 0;
    while(ptr != 0ul)
    {
        temp[ctr] = ptr % 16ul;
        ptr = ptr >> 4;             // Faster div by 16
        ctr++;
    }


    out[0] = '0';
    out[1] = 'x';

    u32 i;
    for(i = 0; i < ctr; ++i)
    {
        out[2+i] = val_to_ascii(temp[ctr-1-i]);
    }

    out[2 + ctr] = 0;

    return 3+ctr;
}

// ============================================================================
// GOT helpers
// ============================================================================

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

// Print the contents of the GOT. Cant seem to find a good way to find its size
// at runtime so F it, we gonna just print the first 5 entries and call it good
void print_GOT()
{
    u32 len;
    char temp[70];
    u64 GOT;
    u64 val;
    int i;
    char c;

    for(i = 0; i < 5; ++i)
    {
        my_puts("| GOT[", 6);
        c = val_to_ascii((u64) i);
        my_puts(&c, 1);
        my_puts("] | ", 4);

        GOT = getGOT(i*8);

        len = ptr_to_hex_str(GOT, temp);
        my_puts(temp, len);

        val = *((u64*) GOT);

        len = ptr_to_hex_str(val, temp);
        my_puts(" | ", 3);
        my_puts(temp, len);
        my_puts(" |\n", 3);
    }
    my_puts("\n", 1);
}

int my_getpid()
{
    asm(
        "mov $0x27, %rax\n"
        "syscall\n"
        "pop %rbp\n"
        "ret\n"
    );
}

void _my_read(int fd, char* buf, int c)
{
    asm(
        "mov $0, %rax\n"
        "syscall\n"
    );
}

void wait()
{
    _my_read(0, 0, 1);
}

// ============================================================================
// Test Drivers
// ============================================================================
#if TEST_VAL_TO_ASCII
void test_val_to_ascii()
{
    char t[2];
    t[1] = 0;

    int i;
    for(i = 0; i < 16; ++i)
    {
        t[0] = val_to_ascii(i);
        my_puts(t, 2);
    }

    return;
}
#endif

#if TEST_PTR_TO_HEX_STR
void test_ptr_to_hex_str()
{
    char t1[70];
    u32 len;

    void* ptr0 = (void*) 0x1;
    len = ptr_to_hex_str((u64) ptr0, (char*) t1);
    my_puts(t1, len);
    my_puts("\n", 2);
    
    void* ptr1 = (void*) 0x1000;
    len = ptr_to_hex_str((u64) ptr1, (char*) t1);
    my_puts(t1, len);
    my_puts("\n", 2);
    
    void* ptr2 = (void*) 0xabcdef123;
    len = ptr_to_hex_str((u64) ptr2, (char*) t1);
    my_puts(t1, len);
    my_puts("\n", 2);

}
#endif

// ============================================================================
// Start and Exit
// ============================================================================

// Call assembly syscall to exit the process
void my_exit()
{
    asm(
        "mov $60, %rax\n"
        "syscall\n"
    );
}

void _start()
{
    #if TEST_VAL_TO_ASCII
        test_val_to_ascii();
    #endif

    #if TEST_PTR_TO_HEX_STR
        test_ptr_to_hex_str();
    #endif

    // Start of actual investigation
    print_GOT();
    inc_counter();
    print_GOT();

    // Print pid and wait for input
    int pid = my_getpid();
    char my_pid[17];
    int len = ptr_to_hex_str(pid, my_pid);
    my_pid[len -1] = '\n';
    my_puts(my_pid, len);
    wait();

    my_exit();
}