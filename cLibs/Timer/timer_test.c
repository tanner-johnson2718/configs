#include "timer.h"
#include <stdio.h>
#include <unistd.h>

int main(){

	my_time_t time;

	tick(&time);
	sleep(1);
	tock(&time);

	printf("cpu: %lf  sys: %lf\n", time.cputime, time.systime);
}