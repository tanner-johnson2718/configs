// Test driver for job Q (Q.cc)

#include "Q.h"
#include <stdio.h>

int main(){
	Q_t *jobQ = init_Q(5);

	int i;
	for(i = 0; i < 5; ++i){
		printf("Adding\n");
		addJob(NULL, NULL, jobQ); 
		printf("numJobs: %d head: %d tail: %d\n\n", jobQ->numJobs, jobQ->head, jobQ->tail);
	}

	for(i = 0; i < 2; ++i){
		printf("Popping\n");
		getNextJob(jobQ);
		printf("numJobs: %d head: %d tail: %d\n\n", jobQ->numJobs, jobQ->head, jobQ->tail);
	}

	for(i = 0; i < 6; ++i){
		printf("Adding\n");
		addJob(NULL, NULL, jobQ); 
		printf("numJobs: %d head: %d tail: %d\n\n", jobQ->numJobs, jobQ->head, jobQ->tail);
	}


	free_Q(jobQ);
}