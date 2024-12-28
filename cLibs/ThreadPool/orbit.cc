// orbit.cc implements an interesting application of the ThreadPool. It random initializes the
// posistions and velocities of simulated particles. It then updates theses particles based on the
// gravitational force they exert on each other. These operations are done in parallel.

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>
#include "threadPool.cc"

struct particle{
	double x;
	double y;
	double vx;
	double vy;
	double mass;
};

int numUpdateThreads = 1;
int numIters = 5;
int numParticles = 5;

double gravConst = 1;
double timeStep = .1;

struct particle *parts;

static inline int min(int x , int y){
	if(x < y){
		return x;
	}

	return y;
}


static inline double dist(struct particle *p1, struct particle *p2){
	return sqrt(pow(((p1->x) - (p2->x)),2) + pow(((p1->y) - (p2->y)),2)); 
}

// Thread func to update posistion
// The thread is passed an int 0 to numUpdateThreads - 1. this int describes what particles the the thread update.
// if a thread is passed i, then  it  will update i*ciel(numParticles/numThreads) to min((i+1)*ciel(numParticles/numThreads) , numParts)
// **Uses Block partition scheme: data is divided into blocks and each
void* posT(void* in){
	int index = *((int*) in);
	int size = ceil((double) numParticles/numUpdateThreads);
	int i;

	for(i = index*size; i < min((index+1) * size, numParticles); i++){
		parts[i].x += parts[i].vx * timeStep;
		parts[i].y += parts[i].vy * timeStep;
	}

	return NULL;
}

// update posistion of particles based on each particles current velocity
// This is done in parralel. The list of particles is divided up based on
// the number threads, and each thread updates the particles it is assigned too
void updatePos(int *indicies){
	 int i;

	 for(i = 0; i < numUpdateThreads; i++){
	 	threadPool::postJob(&indicies[i], posT);
	 }

	 threadPool::blockTilDone();

}

void printPos(){ 
	int i;
	for(i = 0; i < numParticles; i++){
		printf("Particle %d: x: %lf y: %lf\n", i, parts[i].x, parts[i].y);
	}

	printf("\n");
}

// update velocities of particles based on inverse square law
void updateVel(){
	// signal vel update threads

	// wait till all signal back
}


int main(){
	// create array of particles and seed random num gem
	parts = new struct particle;
	srand(time(NULL));

	// init array of particles
	int i;
	for(i = 0; i < numParticles; i++){
		parts[i].x = 0; //rand() / (double) RAND_MAX;
		parts[i].y = 0; //rand() / (double) RAND_MAX;
		parts[i].vx = 1; //rand() / (double) RAND_MAX;
		parts[i].vy = 1; //rand() / (double) RAND_MAX;
		parts[i].mass = 1;
	}

	// init threadPool and indicies
	threadPool::init(numUpdateThreads, numParticles);
	int *indicies = new int[numParticles];

	for(i = 0; i < numParticles; i++){
		indicies[i] = i;
	}

	// main update loop
	for(i = 0; i < numIters; i++){
		// update velocities
		updatePos(indicies);
		printPos();
	}

	threadPool::destroy();
	delete parts;
	delete  indicies;
}