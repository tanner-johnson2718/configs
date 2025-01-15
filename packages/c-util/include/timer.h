// header for timing code

#ifndef TIMER_H_
#define TIMER_H_

#include <sys/time.h>
#include <time.h>

struct my_time {
	double cputime;    // total cpu time in ms
	double systime;    // total system time in ms
	struct timeval time;
	clock_t start;
} typedef my_time_t;

void tick(my_time_t*);            // start timer
void tock(my_time_t*);       // stop timer and return time

#endif 
