// Q implementation. See header for details

#include "Q.h"

#include <stdlib.h>
#include <stdio.h>

// Create the Q
Q_t* init_Q(int init_maxJobs){
	Q_t* q = malloc(sizeof(Q_t));
	q->size = init_maxJobs;
	q->numJobs = 0;
	q->list = malloc(init_maxJobs * sizeof(job_t));
	q->head = 0;
	q->tail = 0;
	return q;
}

// Add a job to the Q
void addJob(void* arg, void *(*job_func) (void *), Q_t* q){
	// Make sure there is room
	if(q->numJobs + 1 == q->size){
		q->list = realloc(q->list, 2 * q->size  * sizeof(job_t));
		q->size = 2 * q->size;
	}

	// insert job at tail
	q->list[q->tail].arg = arg;
	q->list[q->tail].job_func = job_func;

	// update the tail and numJobs
	q->tail = (q->tail + 1) % q->size;
	q->numJobs++;
}

job_t getNextJob(Q_t* q){
	struct job ret;

	if(q->numJobs == 0){
		ret.arg = NULL;
		ret.job_func = NULL;
		return ret;
	}

	// get head of list
	ret.arg = q->list[q->head].arg;
	ret.job_func = q->list[q->head].job_func;

	// update head and number jobs
	q->head = (q->head + 1) % q->size;
	q->numJobs--;

	return ret;
}

// Destroy Q
void free_Q(Q_t* q){
	free(q);
	free(q->list);
}