#include "lib_meme.h"
#include <wait.h>

static const u32 child1_in_own_grp = 1;

void _start()
{

    ///////////////////////////////////////////////////////////////////////////
    // PARENT Start
    ///////////////////////////////////////////////////////////////////////////

    meme_puts("PARENT Starts\n", 14);
    meme_print_key_val_line("PARENT pid", 10, 20, meme_getpid());
    meme_print_key_val_line("PARENT gid", 10, 20, meme_getpgid(0));
    meme_puts("\n", 1);

    ///////////////////////////////////////////////////////////////////////////
    // CHILD 1 Start
    ///////////////////////////////////////////////////////////////////////////
    s32 pid = meme_fork();
    if(pid == 0)
    {
        if(child1_in_own_grp)
        {
            meme_setpgid(0,0);
        }

        meme_puts("CHILD_1 Starts\n", 15);
        meme_print_key_val_line("CHILD_1 pid", 11, 20, meme_getpid());
        meme_print_key_val_line("CHILD_1 ppid", 12, 20, meme_getppid());
        meme_print_key_val_line("CHILD_1 gid", 11, 20, meme_getpgid(0));
        meme_puts("\n", 1);

        s32 pid_1_1 = meme_fork();

        ///////////////////////////////////////////////////////////////////////////
        // CHILD 1_1 Starts
        ///////////////////////////////////////////////////////////////////////////

        
        if(pid_1_1 == 0)
        {
            meme_puts("CHILD_1_1 Starts\n", 17);
            meme_print_key_val_line("CHILD_1_1 pid", 13, 20, meme_getpid());
            meme_print_key_val_line("CHILD_1_1 ppid", 14, 20, meme_getppid());
            meme_print_key_val_line("CHILD_1_1 gid", 13, 20, meme_getpgid(0));
            meme_puts("\n", 1);
            
            meme_puts("CHILD_1_1 waiting ...\n", 22);
            meme_sleep(2);

            meme_exit(0x69);
        }

    ///////////////////////////////////////////////////////////////////////////
    // CHILD 1 reaps CHILD 1_1
    ///////////////////////////////////////////////////////////////////////////

        s32 stat1 = 0x0;
        u8 buff[16];
        s32 ret = meme_waitpid(pid_1_1, &stat1, 0);
        if(ret != pid_1_1)
        {
            meme_puts("ERROR, waitpid, failed\n", 23);
            meme_exit(1);
        }
        meme_puts("CHILD_1 Reaps CHILD_1_1\n", 24);
        u32 len = ptr_to_hex_str((u64) WEXITSTATUS(stat1), buff, 16);
        meme_puts("CHILD_1_1 Exit Stat = ", 22);
        meme_puts(buff, len-1);
        meme_puts("\n", 1);
        meme_puts("\n", 1);
        meme_exit(0x420);
    }

    ///////////////////////////////////////////////////////////////////////////
    // CHILD 2 Start
    ///////////////////////////////////////////////////////////////////////////
    meme_sleep(1);
    s32 pid2 = meme_fork();
    if(pid2 == 0)
    {
        meme_puts("CHILD_2 Starts\n", 15);
        meme_print_key_val_line("CHILD_2 pid", 11, 20, meme_getpid());
        meme_print_key_val_line("CHILD_2 ppid", 12, 20, meme_getppid());
        meme_print_key_val_line("CHILD_2 gid", 11, 20, meme_getpgid(0));
        meme_puts("\n", 1);

        meme_exit(0xbeef);
    }

    ///////////////////////////////////////////////////////////////////////////
    // PARENT Moves CHILD_2 if set
    ///////////////////////////////////////////////////////////////////////////
    if(child1_in_own_grp)
    {
        if(meme_setpgid(pid2, pid))
        {
            meme_puts("\n\nERROR, setpgid FAILED\n\n", 25);
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // PARENT Reaps CHILD_1_1
    ///////////////////////////////////////////////////////////////////////////
    s32 stat = 0x0;
    u8 buff[16];
    s32 ret = meme_waitpid(pid, &stat, 0);
    if(ret != pid)
    {
        meme_puts("ERROR, waitpid, failed\n", 23);
        meme_exit(1);
    }
    meme_puts("PARENT Reaps CHILD_1\n", 22);
    u32 len = ptr_to_hex_str((u64) WEXITSTATUS(stat), buff, 16);
    meme_puts("CHILD_1 Exit Stat = ", 20);
    meme_puts(buff, len-1);
    meme_puts("\n", 1);
    meme_puts("\n", 1);

    ///////////////////////////////////////////////////////////////////////////
    // PARENT Reaps CHILD_2
    ///////////////////////////////////////////////////////////////////////////
    ret = meme_waitpid(pid2, &stat, 0);
    if(ret != pid2)
    {
        meme_puts("ERROR, waitpid, failed\n", 23);
        meme_exit(1);
    }
    meme_puts("PARENT Reaps CHILD_2\n", 22);
    len = ptr_to_hex_str((u64) WEXITSTATUS(stat), buff, 16);
    meme_puts("CHILD_2 Exit Stat = ", 20);
    meme_puts(buff, len-1);
    meme_puts("\n", 1);

    meme_exit(0);
}