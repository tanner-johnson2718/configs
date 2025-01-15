#include "lib_meme.h"

// ============================================================================
// Sys Calls
// ============================================================================
u64 meme_generic_syscall3(u64 arg1, u64 arg2, u64 arg3, u64 syscall_num)
{
    asm(
        "mov %rcx, %rax\n"
        "syscall\n"
    );
}

s32 meme_read(u32 fd, void* buff, u32 count)
{
   asm(
        "mov $0,%rax\n"
        "syscall\n"
   );
}

s32 meme_write(u32 fd, void* buff, u32 count)
{
    asm(
        "mov $1,%rax\n"
        "syscall\n"
   );
}

s32 meme_getpid(void)
{
    asm(
        "mov $39,%rax\n"
        "syscall\n"
   );
}

s32 meme_getppid(void)
{
    asm(
        "mov $110,%rax\n"
        "syscall\n"
   );
}

void meme_exit(s32 stat)
{
    asm(
        "mov $60,%rax\n"
        "syscall\n"
   );
}

s32 meme_puts(u8* str, u32 len)
{
    meme_write(1, str, len);
}

s32 meme_fork(void)
{
    asm(
        "mov $57,%rax\n"
        "syscall\n"
   );
}

s32 meme_waitpid(s32 pid, s32* wstatus, s32 options)
{
    asm(
        "mov $61,%rax\n"
        "mov $0, %r10\n"
        "syscall\n"
   );
}

s32 meme_wait4(s32 pid, s32 *wstatus, int options, struct rusage *rusage)
{
    asm(
        "mov $61,%rax\n"
        "syscall\n"
   );
}

s32 meme_getrusage(s32 who, struct rusage *usage)
{
    asm(
        "mov $98,%rax\n"
        "syscall\n"
   );
}

u32 meme_alarm(u32 sec)
{
    asm(
        "mov $37, %rax\n"
        "syscall\n"
    );
}

s32 meme_pause()
{
    asm(
        "mov $34, %rax\n"
        "syscall\n"
    );
}

u64 meme_brk(u64 in)
{
    asm(
        "mov $12, %rax\n"
        "syscall\n"
    );
}

s32 meme_getpgid(s32 pid)
{
    asm(
        "mov $121, %rax\n"
        "syscall\n"
    );
}

s32 meme_setpgid(s32 pid, s32 pgid)
{
     asm(
        "mov $109, %rax\n"
        "syscall\n"
    );
}

s32 meme_nanosleep(u64* ptr1, u64* ptr2)
{
    asm(
        "mov $35, %rax\n"
        "syscall\n"
    );
}

s32 meme_sleep(u32 sec)
{
    u64 a = (u64) sec;
    u64 b = 0;
    u64 c = 0;
    u64 d = 0;

    return meme_nanosleep(&a, &c);
}

s32 meme_kill(u32 pid, u32 sig)
{
    asm(
        "mov $62, %rax\n"
        "syscall\n"
    );
}

s32 meme_gettid(void)
{
    asm(
        "mov $186, %rax\n"
        "syscall\n"
    );
}

void* meme_mmap(void* addr, u64 len, s32 prot, s32 flags, s32 fd, u64 off)
{
    asm(
        "mov %rcx, %r10\n"    // for some reason 4th arg in C is %rcx but for syscall is %r10
        "mov $9, %rax\n"
        "syscall\n"
    );
}

s32 meme_munmap(void* addr, u64 off)
{
    asm(
        "mov $11, %rax\n"
        "syscall\n"
    );
}

s64 meme_clone(u64 flags, void *stack, s32* parent_tid, s32* child_tid, u64 tls)
{
    asm(
        "mov %rcx, %r10\n"    // for some reason 4th arg in C is %rcx but for syscall is %r10
        "mov $56, %rax\n"
        "syscall\n"
    );

    // Child
    register u64 ret asm("rax");
    if(ret == 0)
    {
        
        asm(
            "call %r8\n"
        );
    }
}


// ============================================================================
// String Manip
// ============================================================================

// Take in a u64 and convert it to its ascii value.
u8 val_to_ascii(u64 in)
{
    if(in < 10ul)
    {
        return (u8) (in + '0');     // 48 = ascii('0')
    }

    // 97 = ascii('a'). Subtract 10 so that 10 -> 'a'.
    return (char) (in -10ul + 'a');          
}

// Convert the ptr to a hex ascii string. Return number of byte written. If out
// str is not big enough, then simply write as much as we can until full.
u32 ptr_to_hex_str(u64 ptr, u8* out, u32 out_size)
{

    u64 temp[16];
    u32 ctr = 0;

    // Mod it 16 to find lowest digit. Divide by 16 then mod again to find next
    // lowest digit. Loop this until we get 0;
    while(ptr != 0ul && ctr < 16)
    {
        temp[ctr] = ptr % 16ul;
        ptr = ptr >> 4;             // Faster div by 16
        ctr++;
    }

    if(out_size >= 2)
    {
        out[0] = '0';
        out[1] = 'x';
    }
    else
    {
        return 0;
    }
    

    u32 i;
    for(i = 0; (i < ctr) && ((i+2) < (out_size -1)); ++i)
    {
        out[2+i] = val_to_ascii(temp[ctr-1-i]);
    }

    out[2 + i] = 0;

    return 3+i;
}

// Print a string value pair line. The value will always be assumed to be a 
// hex 64 bit value. A max char param can be passed such that the key value
// pairs are vertically aligned
void meme_print_key_val_line(u8* str, u32 len, u32 align, u64 val)
{
    const u32 max_str_len = 64;
    if(align < len){
        meme_puts("ERROR, align < len\n", 19);
        return;
    }

    if(align > max_str_len)
    {
        meme_puts("ERROR, align > max_str_len\n", 27);
        return;
    }

    u8 temp[20];
    u32 temp_len = ptr_to_hex_str(val, temp, 20);

    u32 pad_len = align - len;
    char pad[pad_len];
    int i = 0;
    for(; i < pad_len; ++i)
    {
        pad[i] = ' ';
    }

    meme_puts("KEY= ", 5);
    meme_puts(str, len);
    meme_puts(pad, pad_len);
    meme_puts("  VAL= ", 7);
    meme_puts(temp, temp_len-1);
    meme_puts("\n", 1);
}