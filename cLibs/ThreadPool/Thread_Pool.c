// Thread Pool implementation. When a thread pool is created, the user must specify the
// number of working threads it would like it to contain and the max number of Jobs. 
// When init-ed the threads are spawned and block until jobs are posted in post job

// One can block until all jobs are done with the function blockTilDone.

// Note there is no garenteed order by which the jobs are finished or started

// Note functions are not thread safe. Calls to any funcs should be done
// atomically ie not in parralel. Functions are not re-entrant safe either

// See Q.h for declarations related to the jobQ
#include "Thread_Pool.h"
#include "Q.h" 
#include <pthread.h>
#include <stdio.h>
#include <signal.h>
#include <stdlib.h>

inline void lock(pthread_mutex_t *m){
	if(pthread_mutex_lock(m)){
		printf("Failed to lock mutex\n");
		exit(1);
	}
}

inline void unlock(pthread_mutex_t *m){
	if(pthread_mutex_unlock(m)){
		printf("Failed to unlock mutex\n");
		exit(1);
	}
}

inline void wait(pthread_mutex_t *m, pthread_cond_t *c){
	if(pthread_cond_wait(c,m)){
		printf("Failed to wait\n");
		exit(1);
	}
}

inline void broadcast(pthread_cond_t *c){
	if(pthread_cond_broadcast(c)){
		printf("Failed to broadcast\n");
		exit(1);
	}
}

void* tfunc(void* in){
	struct Q::job j;

	while(1){
		// wait for job to be posted
		lock(&job_mutex);
		while(jobQ->numJobs == 0){
			wait(&job_mutex, &job_cond);

			// check if thread pool has been terminated
			if(terminate != 0){
				unlock(&job_mutex);
				return NULL;
			}
		}

		// grab most recent job and indicate thread is running
		j = jobQ->getNextJob();
		jobs_running++;

		// release jobQ mutex
		unlock(&job_mutex);

		// execute the job
		j.job_func(j.arg);

		// indicate job done by dec jobs running and broadcasting
		lock(&job_mutex);
		jobs_running--;
		broadcast(&block_cond);
		unlock(&job_mutex);
	}
}	

// // blocks until all jobs have finished
void blockTilDone(tpool_t* pool){
	// wait for broadcast over block_cond
	// proceed only if there are no jobs running
	lock(&(tpool->job_mutex));
	while((tpool->jobs_running > 0) || (tpool->jobQ->numJobs > 0)){
		wait(&(tpool->job_mutex),&(tpool->block_cond));
	}
	unlock(&(tpool->job_mutex));
}	

// // Post a job in the Q and broadcast to all waiting thread.
// // Note make sure arg stays in scope for the duration of the job
void postJob(void* arg, void *(*job_func) (void *), tpool_t* pool){
	lock(&(tpool->job_mutex));
	addJob(arg, job_func);
	unlock(&(tpool->job_mutex));
	broadcast(&(tpool->job_cond));
}

// Create Thread Pool. Init sync vars, array of threads, and the Q of jobs.
// Then spawn all the threads 
void init_tpool(int numT, tpool_t* pool){
	// init sync variables
	if(pthread_mutex_init(&(pool->job_mutex), NULL)){
		printf("Failed to init mutex\n");
		exit(1);
	}
	if(pthread_cond_init(&(pool->job_cond), NULL)){
		printf("Failed to init cond\n");
		exit(1);
	}
	if(pthread_cond_init(&(pool->block_cond), NULL)){
		printf("Failed to init cond\n");
		exit(1);
	}

	// init array of threads and jobQ
	pool->num_threads = numT;
	pool->threads = malloc(numT * sizeof(pthread_t));
	pool->jobQ = init_Q(INIT_JOBQ_SIZE);
	pool->jobs_running = 0;
	pool->terminate = 0;

	// spawn threads
	int i = 0;
	for(; i < numT; i++){
		if(pthread_create(&(pool->threads[i]), NULL, tfunc, NULL)){
			printf("Failed to init threads\n");
			exit(1);
		}
	}
}

// clean up thread pool
void destroy_tpool(tpool_t* pool){
	// Wait for jobs to finish
	blockTilDone();

	// kill threads
	lock(&(tpool->job_mutex));
	tpool->terminate = 1;
	unlock(&(tpool->job_mutex));
	broadcast(&(tpool->job_cond));

	int i;
	for(i = 0; i < tpool->numThreads; i++){
		if(pthread_join(tpool->threads[i], NULL)){
			printf("Failed to join\n");
		}
	}

	// clean up mutex and cond var
	int e1 = pthread_mutex_destroy(&(tpool->job_mutex));
	int e2 = pthread_cond_destroy(&(tpool->job_cond));
	int e3 = pthread_cond_destroy(&(tpool->block_cond));
	if((e1 != 0) || (e2 != 0) || (e3 != 0)){
		printf("Failed to clean up mutex and cv's");
	}

	// clean up jobQ and thread array
	free_Q(tpool->Q);
	free(tpool->threads);

}