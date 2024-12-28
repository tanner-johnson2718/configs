// file to call sbrk libc function and see what the underlying sys call is
// using strace.

#include <unistd.h>
#include <stdio.h>

unsigned long test(unsigned long in)
{
    asm(
        "mov $12, %rax\n"
        "syscall\n"
    );
}

int main()
{
    printf("b4\n");
    void* ret = (void*) test(0ul);

    printf("Current brk = %p\n", ret);
}