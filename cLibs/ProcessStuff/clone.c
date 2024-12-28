#include "lib_meme.h"

#define n_threads 2
void* stack_list[n_threads];
s32 parent_tid = -1; 
s32 thread_tids[n_threads] = {0};
const u32 stack_size = 1024*1024;

// Use same Clone flags as pthread create
const u64 clone_flags = CLONE_SIGHAND | CLONE_FS | CLONE_VM | CLONE_FILES | 
                        CLONE_THREAD | CLONE_IO;

void f(void){
    s32 tid = meme_gettid();
    s32 pid = meme_getpid();
    s32 ppid = meme_getppid();
    s32 pgid = meme_getpgid(0);

    meme_sleep((tid - parent_tid) % 5);
    meme_print_key_val_line("Syscall TID", 11, 20, tid);
    meme_print_key_val_line("PID", 3, 20, pid);
    meme_print_key_val_line("PPID", 4, 20, ppid);
    meme_print_key_val_line("PGID", 4, 20, pgid);
    meme_puts("\n", 1);

    meme_exit(1);
}

void _start()
{
    s32 parent_tid = meme_gettid();
    s32 parent_pid = meme_getpid();
    s32 parent_ppid = meme_getppid();
    s32 parent_pgid = meme_getpgid(0);

    meme_sleep(1);
    meme_print_key_val_line("Syscall TID", 11, 20, parent_tid);
    meme_print_key_val_line("PID", 3, 20, parent_pid);
    meme_print_key_val_line("PPID", 4, 20, parent_ppid);
    meme_print_key_val_line("PGID", 4, 20, parent_pgid);

    // Map mem for thread stacks
    int i;
    for(i = 0; i < n_threads; ++i)
    {
        stack_list[i] = meme_mmap(NULL, stack_size, PROT_READ|PROT_WRITE, MAP_STACK | MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);
        if((s64) stack_list[i] < 0l)
        {
            meme_puts("MMAP FAILED!\n", 13);
            meme_exit(1);
        }
    }
    
    // Spawn threads
    for(i = 0; i < n_threads; ++i)
    {
        s32 ret_tid = meme_clone(clone_flags, stack_list[i] + stack_size -1, NULL, 
                            NULL, (u64) f);

        thread_tids[i] = ret_tid;

        meme_print_key_val_line("Parent Ret", 10, 15, ret_tid);
        meme_puts("\n", 1);
    }

    meme_sleep(5);
    meme_puts("exiting parent\n", 15);

    // Clean Stacks
    for(i = 0; i < n_threads; ++i)
    {
        if(meme_munmap(stack_list[i], stack_size) < 0)
        {
            meme_puts("MUMAP FAILED!\n", 13);
            meme_exit(1);
        }
    }
    

    meme_exit(0);
}