#include "lib_meme.h"

void test_ptr_to_hex_str()
{
    u32 buff_size = 70;
    u8 t1[buff_size];
    u32 len;

    void* ptr0 = (void*) 0x1;
    len = ptr_to_hex_str((u64) ptr0, (u8*) t1, buff_size);
    meme_puts(t1, len-1);
    meme_puts("\n", 1);
    
    void* ptr1 = (void*) 0x1000;
    len = ptr_to_hex_str((u64) ptr1, (u8*) t1, buff_size);
    meme_puts(t1, len-1);
    meme_puts("\n", 1);
    
    void* ptr2 = (void*) 0xabcdef123;
    len = ptr_to_hex_str((u64) ptr2, (u8*) t1, buff_size);
    meme_puts(t1, len-1);
    meme_puts("\n", 1);

}

void test_val_to_ascii()
{
    char t[2];
    t[1] = 0;

    int i;
    for(i = 0; i < 16; ++i)
    {
        t[0] = val_to_ascii(i);
        meme_puts(t, 1);
    }
    meme_puts("\n", 1);

    return;
}

void _start()
{
    test_val_to_ascii();
    test_ptr_to_hex_str();

    const u32 buff_size = 17;   // +1 for null
    u8 buff[buff_size];

    s32 num_read = meme_read(STD_IN_FD, buff, buff_size-1);
    s32 ret = meme_write(STD_OUT_FD, buff, num_read);

    meme_exit(0);
}