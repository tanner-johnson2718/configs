// Goal it to create process and map various activities to process state val

#include "lib_meme.h"

const static u32 do_sleep = 0;
const static u32 do_unreaped_child=0;
const static u32 do_stop_child=1;

void _start()
{   
    s32 pid = meme_getpid();
    meme_print_key_val_line("PID = ", 6, 10, pid);

    // Sleep state
    if(do_sleep)
    {
        meme_sleep(10);
    }

    // Zombie state
    if(do_unreaped_child)
    {
        s32 cpid = meme_fork();
        if(cpid == 0)
        {
            meme_exit(0);
        }

        meme_print_key_val_line("CPID = ", 7, 10, cpid);
        meme_puts("Waiting To reap child\n", 22);
        meme_sleep(60);

        meme_waitpid(0, NULL, 0);
    }

    // Stop state
    if(do_stop_child)
    {
        s32 cpid = meme_fork();
        if(cpid == 0)
        {
            meme_exit(0);
        }

        meme_print_key_val_line("CPID = ", 7, 10, cpid);
        
        meme_puts("Stopping child\n", 15);
        meme_kill(cpid, 19);

        meme_sleep(60);

        meme_puts("Cont child\n", 11);
        meme_kill(cpid, 18);

        meme_waitpid(0, NULL, 0);
    }

    meme_exit(0);
}