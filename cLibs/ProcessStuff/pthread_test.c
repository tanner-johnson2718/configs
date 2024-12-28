#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

void* f(void* in)
{
    printf("here child\n");
}

int main()
{
    pthread_t thread1;
    int iret1 = pthread_create( &thread1, NULL, f, NULL);
    pthread_join( thread1, NULL);
    return 0;
}