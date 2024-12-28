#include "lib_meme.h"

void _start()
{
    const u32 iters = 0;
    const u32 null_buff_len = 0;
    const u64 heap_alloc = 10*1024*1024;

    // Iterate to force some user cpu time and some involuntary context 
    // switches
    if(iters > 0)
    {
        u32 i, j;
        for(i = 0; i < iters; ++i)
        {
            j += i;
        }
    }

    // Print some null bytes to the screen to force system cpu time
    if(null_buff_len > 0)
    {

        u32 i = 0;
        for(; i < null_buff_len; ++i)
        {
            u8 c = 0;
            meme_puts(&c, 1);
        }
    }

    // Allocate some heap space to push the max RSS value.
    if(heap_alloc > 0)
    {
        u64 start = meme_brk(NULL);
        u64 end = meme_brk(start + heap_alloc);

        if(start < 0 || end < 0)
        {
            meme_puts("brk failed\n", 11);
            meme_exit(1);
        }

        if(end - start != heap_alloc)
        {
            meme_puts("brk did not allocate full mem\n", 29);
            meme_exit(1);
        }


        // Trivially access mem to get some page faults
        int i;
        for(i = 0; i < heap_alloc; ++i)
        {
            ((u8*)start)[i] = 0ul;
        }
    }

    struct rusage ruse = {0};

    s32 ret = meme_getrusage(RUSAGE_SELF, &ruse);
    if(ret < 0)
    {
        meme_puts("RUSAGE FAILED, OH NO!", 21);
        meme_exit(1);
    }

    u32 pad = 25;

    meme_print_key_val_line("user cpu sec", 12, pad, ruse.ru_utime.tv_sec);
    meme_print_key_val_line("user cpu usec", 13, pad, ruse.ru_utime.tv_usec);
    meme_print_key_val_line("system cpu sec", 14, pad, ruse.ru_stime.tv_sec);
    meme_print_key_val_line("system cpu usec", 15, pad, ruse.ru_stime.tv_usec);
    meme_print_key_val_line("Max RSS", 7, pad, ruse.ru_maxrss);
    meme_print_key_val_line("None IO Page Faults", 19, pad, ruse.ru_minflt);
    meme_print_key_val_line("Page Faults", 11, pad, ruse.ru_majflt);
    meme_print_key_val_line("# File Input", 12, pad, ruse.ru_inblock);
    meme_print_key_val_line("# File Output", 13, pad, ruse.ru_oublock);
    meme_print_key_val_line("Vol. Context Switch", 19, pad, ruse.ru_nvcsw);
    meme_print_key_val_line("Forced Contect Switch", 21, pad, ruse.ru_nivcsw);

    meme_exit(0);
}
