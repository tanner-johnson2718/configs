#ifndef _T_POOL_H_
#define _T_POOL_H_

#define INIT_JOBQ_SIZE 512

#include <pthread.h>
#include "Q.h" 

struct tpool{

    // Syncronization variables
    pthread_mutex_t job_mutex;   // mutex to control access to jobQ and jobs running
    pthread_cond_t job_cond;     // cond variable to indicate jobs are available
    pthread_cond_t block_cond;   // cond variable to indicate a job has finished
    int jobs_running;            // indicate number of jobs currently running
    Q_t *jobQ;                   // queue for holding jobs to be completed

    // Array to store pthread_t pointers
    pthread_t *threads;
    int num_threads;

    // Used to indicate if the threads should exit. 0 keep running. Else terminate
    int terminate;

} typedef tpool_t;

void blockTilDone(tpool_t* pool);
void postJob(void* arg, void *(*job_func) (void *), tpool_t* pool);
void init_tpool(int numT, tpool_t* pool);
void destroy_tpool(tpool_t* pool);

#endif