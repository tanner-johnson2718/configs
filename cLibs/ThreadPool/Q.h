// Queue header for job queue in threadPool. The q is a FIFO q implemented
// by an array and a pointer pointing to the least recent element in the q.
// It supports standard ops such as getting the head of the q and getting
// the number of elements in the q. Job is dynamic and when full it doubles
// the size of the job list.

#ifndef Q_H_
#define Q_H_

// Struct to rep a job. Contains the function to be executed and the input param
struct job{
	void *arg;                       // Job function argument
	void *(*job_func) (void *);      // Job function pointer
} typedef job_t;

struct Q{
	int size;            // Size of the Q
	int numJobs;         // Number of active jobs in the list
	struct job *list;    // The array containing the list
	int head;            // Index of the head of the list (least recent)
	int tail;            // Index of the next open spot in list
} typedef Q_t;

Q_t* init_Q(int init_maxJobs);                                // Create a Q
void addJob(void* arg, void *(*job_func) (void *), Q_t* q); // Add a job to back of list if space
job_t getNextJob(Q_t* q);                            // Remove and return head of q
void free_Q(Q_t* q);                                      // free a Q
#endif