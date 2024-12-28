// Test Driver and timing code for threadPool. 
// This script examines the max performance (in GFLOP/s) and bandwidth (in GB/s)
// of the CPU using one thread and multiple threads. This uses the thread pool
// code in threadPool.cc to spawn and manage the threads. Several tests using
// different access patterns are explored.

#include "threadPool.cc"
#include "../Timer/timer.h"
#include <stdio.h>
#include <sys/time.h>

// ********************** Start of FLOP Test **********************
// The flop test is simple. Each thread is given a certain amount of floating point
// it must perform. All threads are launched and timed. The rate is then calculated
// reported.

// Two tests are run, one with only one thread and one with several threads.
// Both times are reported

int N = 1 << 25; 	  // ~(32M) FLOPs per thread
int numT = 8;         // Number of threads (if doing cycle mem test use base 2 to avoid rounding errors)

// ********************** Run numT*4*N flop in parralel **********************

void* func1(void* in){
	double param = *((double*) in);
	//printf("Thread started: %d\n", param);

	// inc the input N times
	double i;
	for(i = 0; i < N; i++){
		param++;                   // two flop per iteration
	}

	// dec the input N times
	for(i = 0; i < N; i++){
		param--;                   // two flop per iteration
	}

	//printf("Thread done: %d\n", param);
}

void flopPar(int *indicies){

	int i;
	for(i = 0; i < numT; i++){
		indicies[i] = i;
		threadPool::postJob(&indicies[i], func1);
	}

	threadPool::blockTilDone();

}

// ********************** Run numT*4*N flop sequentially **********************

void* func2(void* in){
	//printf("Thread started: %d\n", param);

	
	double i;
	double j;
	double param;
	for(j = 0; j < numT; j++){
		param = ((double*) in)[(int) j];

		// inc the input N times
		for(i = 0; i < N; i++){
			param++;                    // two flop per iteration
		}

		// dec the input N times
		for(i = 0; i < N; i++){
			param--;                   // two flop per iteration
		}
	}

	//printf("Thread done: %d\n", param);
}

void flopSeq(int *indicies){

	threadPool::postJob(indicies, func2);

	threadPool::blockTilDone();
}


// ********************** Run FLOP Test **********************

void flopTest(){
	threadPool::init(numT, numT);

	int *indicies = new int[numT];
	timer *t = new timer();
	struct timer::my_time seq;
	struct timer::my_time par;

	t->tick();
	flopSeq(indicies);
	seq = t->tock();

	t->tick();
	flopPar(indicies);
	par = t->tock();

	double load = (double) 4.0*numT*N / 1.e6;
	printf("FLOP Test: Threads=%d   Load=%lf Mflop\n", numT, load);
	printf("Seq CPU time: %lf   SYS time: %lf (ms)   Rate=%lf Mflop/s\n", seq.cputime, seq.systime, load * 1000.0 / seq.systime);
	printf("Par CPU time: %lf   SYS time: %lf (ms)   Rate=%lf Mflop/s\n", par.cputime, par.systime, load * 1000.0 / par.systime);

	threadPool::destroy();

	delete[] indicies;
	delete t;

	printf("DONE\n\n");
}

// ********************** Start of Mem Test **********************
// A large array is allocated and the amount of time it takes to read
// every element in the array is timed and reported.
//
// Several differnt tests are ran:
// memSeq spawns one thread and it alone accesses the entire array.
//
// memParBlock breaks the array into blocks of equal size and each thread
// works only on the block it was assigned. This scheme suffers from cache
// misses b/c each thread is operating on a block larger than the L3 cache 
// (**make sure to set size accordingly so this is true).
//
// memParCycle breaks the array into blocks roughly the size of the L3
// cache (slightly smaller). For each block serveral threads are spawned (*).
// Jobs for accessing the block -the size of the L2 cache- at a time are posted
// and all the threads work on that block. Once the block as been processed
// the next block is loaded and the threads operate on that block.
// This ideally should maximize cache hits and therefor bandwidth.  
// * no new threads are spawned. all the threads are spawned when thread pool 
//   is created (init). the threads block until jobs are posted.  
// ** Note the only drawback to this scheme is the increased overhead
// to organize the increased number of thread jobs.
// *** No increase in perf?


// int numT defined above
int size = 1 << 25;  // (16M) ints per thread
int* param;          // array to access

// ********************** Access Array 1 thread **********************

void* func3(void* in){
	int i;
	int read;
	for(i = 0; i < numT*size; i++){
		read = param[i];
	}
}

void memSeq(){
	threadPool::postJob(NULL, func3);
	threadPool::blockTilDone();
}

// ********************** Access Array in Paralel (BLOCK) **********************

void* func4(void* in){
	int index = *((int*) in);
	int read;

	int i;
	for(i = index*size; i < (index + 1)*size; i++){
		read = param[i];
	}
}

void memParBlock(int* in){
	int i;
	for(i = 0; i < numT; i++){
		in[i] = i;
		threadPool::postJob(&in[i], func4);
	}

	threadPool::blockTilDone();
}

// ********************** Run Mem test **********************

void memTest(){
	threadPool::init(numT, numT);

	int *indicies = new int[numT];
	param = new int[numT*size];

	timer *t = new timer();
	struct timer::my_time seq;
	struct timer::my_time par;

	t->tick();
	memSeq();
	seq = t->tock();

	t->tick();
	memParBlock(indicies);
	par = t->tock();

	double load = (double) numT*size*sizeof(int)/ 1.e6;
	printf("Memory test (Block): Threads=%d   Load=%lfMB sequential accesses\n", numT, (double) numT*size*sizeof(int)/ 1.e6);
	printf("Seq CPU time: %lf   SYS time: %lf (ms)   Rate=%lf (MB/s)\n", seq.cputime, seq.systime, load *1000.0 / seq.systime);
	printf("Par CPU time: %lf   SYS time: %lf (ms)   Rate=%lf (MB/s)\n", par.cputime, par.systime, load *1000.0 / par.systime);

	threadPool::destroy();

	delete[] indicies;
	delete t;
	delete param;

	printf("DONE\n\n");
}

// ********************** Access Array in Paralel (CYCLE) **********************

int L3_cache_size = 1 << 20;   // (4MB)   roughly number of ints that fit in the L3 cache
int L2_cache_size = 1 << 16;   // (256KB) roughly number of ints that fit in the L2 cache
int number_jobs = L3_cache_size / L2_cache_size;    // number of jobs to post on each block
int total_size = numT*size;
int num_blocks = total_size / L3_cache_size;

int block = 0;   // The array param is broken into blocks of size L3 cache. This denotes which block it is currentl working on

void* func5(void* in){
	int index = *((int*) in);
	int i;
	int start = block*L3_cache_size + index*L2_cache_size;
	int end = block*L3_cache_size + (index+1)*L2_cache_size;
	int read;

	for(i = start; i < end; i++){
		read = param[i];
		// param[i] = 10;
	}
}

void memParCycle(){
	int *indicies = new int[number_jobs];
	param = new int[total_size];

	timer *t = new timer();
	struct timer::my_time par;

	threadPool::init(numT, number_jobs);

	// loop through each block and post the jobs
	int i, j;
	for(i = 0; i < number_jobs; i++){
		indicies[i] = i;                        // but first set the indicies
	}

	t->tick();
	for(i = 0; i < num_blocks; i++){
		for(j = 0; j < number_jobs; j++){
			threadPool::postJob(&indicies[j], func5);
		}

		threadPool::blockTilDone();
		block++;
	}
	par = t->tock();

	// print results
	double load = (double) total_size*sizeof(int)/ 1.e6;
	printf("Memory test (Cycle): Threads=%d   Load=%lfMB sequential accesses\n", numT, load);
	printf("CPU time: %lf   SYS time: %lf (ms)   Rate=%lf (MB/s)\n", par.cputime, par.systime, load *1000.0 / par.systime);

	// check results (uncomment the param[i] = 10 in func to check the entire param array is read / written)
	// for(i = 0; i < total_size; i++){
	// 	if(param[i] != 10){
	// 		printf("ERROR!!!!\n");
	// 	}
	// }

	threadPool::destroy();
	delete[] indicies;
	delete t;
	delete param;
}

// ********************** main **********************

int main(){
	//flopTest();
	//memTest();
	memParCycle();
}