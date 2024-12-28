#ifndef __MEME_LIB__
#define __MEME_LIB__

#define u64 unsigned long
#define u32 unsigned int
#define  u8 unsigned char
#define s64 long
#define s32 int
#define  s8 char

#define STD_IN_FD 0
#define STD_OUT_FD 1
#define STD_ERR_FD 2

#define NULL 0

// Calls syscall indicated by syscall number. Limit to 3 args (may need to
// expand later for syscalls that take more params). Uses generic unsigned 64
// bit value. Take care when casting return values and func args
u64 meme_generic_syscall3(u64 arg1, u64 arg2, u64 arg3, u64 syscall_num);

// IO syscalls
s32 meme_read(u32 fd, void* buff, u32 count);
s32 meme_write(u32 fd, void* buff, u32 count);

// Proc syscalls
#include <sys/resource.h>
#include <sys/time.h>
s32 meme_wait4(s32 pid, s32 *wstatus, int options, struct rusage *rusage);
s32 meme_getrusage(s32 who, struct rusage *usage);
s32 meme_getpid(void);
s32 meme_getppid(void);
s32 meme_fork(void);
s32 meme_waitpid(s32 pid, s32* wstatus, s32 options);
void meme_exit(s32 stat);
s32 meme_getpgid(s32 pid);
s32 meme_setpgid(s32 pid, s32 pgid);

// Thread System Calls
s32 meme_gettid(void);
#include <linux/sched.h>
s64 meme_clone(u64 flags, void *stack, s32* parent_tid, s32* child_tid, u64 tls);

// Signals Syscalls
u32 meme_alarm(u32 sec);
s32 meme_pause();
s32 meme_sleep(u32 sec);
s32 meme_kill(u32 pid, u32 sig);

// Mem
#include <sys/mman.h>
u64 meme_brk(u64);
void* meme_mmap(void* addr, u64 len, s32 prot, s32 flags, s32 fd, u64 off);
s32 meme_munmap(void* addr, u64 off);

// Str manip
s32 meme_puts(u8* str, u32 len);
u8 val_to_ascii(u64 in);
u32 ptr_to_hex_str(u64 ptr, u8* out, u32 out_size);
void meme_print_key_val_line(u8* str, u32 len, u32 align, u64 val);



#endif