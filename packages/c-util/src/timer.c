// implementation of timer code

#include "timer.h"
#include <sys/time.h>
#include <time.h>

void tick(my_time_t* t){
	t->start = clock();
	gettimeofday(&(t->time), NULL);
}

void tock(my_time_t* t){
	struct timeval temp;

	gettimeofday(&temp, NULL);
	time_t secs = temp.tv_sec - (t->time).tv_sec;
	suseconds_t ms = temp.tv_usec - (t->time).tv_usec;
	t->systime = (1000*((double) secs)) + (((double) ms) / 1000);
	t->cputime = 1000*((double) (clock() - (t->start)) / CLOCKS_PER_SEC);
	
}