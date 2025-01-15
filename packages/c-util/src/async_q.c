//*****************************************************************************
// Async Queue / Runners. Primitives:
//    * Q - This is the base data structure. Currently operates as a stack
//          with controled access. Posters must wait the poster cv if the q is
//          full. This cv is signaled when a comsumer or getter pops an
//          element off the queue. Elements of the queue are of the same length
//          and *should* be of the same type. Access to the queue both post
//          and get only happens atomically with the lock held.
//
//    * Post - Copies an element from the passed buffer on the queue. If full
//             wait for poster cv signal. On completion signal the getter cv.
//             Is reentrant i.e. can have multiple threads posting at the same
//             time
//
//    * Get - Copies an element form the head of the queue to the passed buffer
//            When empty will block until it recieves a getter cv signal. Upon
//            successful get, will signal the poster cv. Is reentrant.
//
//    * Runners - 
//*****************************************************************************

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <stdint.h>
#include <unistd.h>
#include <stdbool.h>>

typedef struct
{
    pthread_cond_t poster_cv;
    pthread_cond_t getter_cv;
    pthread_mutex_t lock;
    uint32_t element_size;
    uint32_t n_max;
    uint32_t n;
    void* q;
} async_q_t;

typedef void (*async_consumer_t)(void*);

typedef struct
{
    pthread_t pthread;
    uint32_t thread_num;
    uint16_t n_runners;
    async_q_t* q;
    async_consumer_t consume;
    bool killed;
} async_runner_t;

static bool async_q_create(async_q_t* q, uint32_t element_size, uint32_t n_elements)
{
    q->poster_cv = (pthread_cond_t) PTHREAD_COND_INITIALIZER;
    q->getter_cv = (pthread_cond_t) PTHREAD_COND_INITIALIZER;
    q->lock = (pthread_mutex_t) PTHREAD_MUTEX_INITIALIZER;
    q->element_size = element_size;
    q->n_max = n_elements;  
    q->n = 0;
    q->q = calloc(element_size, n_elements);
    if(!(q->q))
    {
        LOG("ERROR", "In async_q_create calloc failure");
        return false;
    }

    return true;
}

// Unsafe. Make sure all threads waiting on the queue are joined and killed
static bool aysnc_q_destroy(async_q_t* q)
{
    bool ret = true;
    if(pthread_mutex_destroy(&(q->lock)))
    {
        LOG("ERROR", "In async_q_destroy failed to destroy lock");
        ret = false;
    }

    if(pthread_cond_destroy(&(q->poster_cv)))
    {
        LOG("ERROR", "In async_q_destroy failed to destroy cv");
        ret = false;
    }

    if(pthread_cond_destroy(&(q->getter_cv)))
    {
        LOG("ERROR", "In async_q_destroy failed to destroy cv");
        ret = false;
    }

    free(q->q);

    return ret;
}

static bool async_post(async_q_t* q, void* elem)
{
    bool ret = true;
    if(pthread_mutex_lock(&(q->lock)))
    {
        LOG("ERROR", "In async_post mutex lock failed");
        return false;
    }

    while(q->n == q->n_max)
    {
        if(pthread_cond_wait(&(q->poster_cv), &(q->lock)))
        {
            LOG("ERROR", "In async_post cond wait failed");
        }
    }

    memcpy(q->q + ((q->n)* (q->element_size)), elem, q->element_size);
    ++(q->n);
    if(pthread_cond_signal(&(q->getter_cv)))
    {
        LOG("ERROR", "In async_post cond signal failed");
        ret = false;
    }


    if(pthread_mutex_unlock(&(q->lock)))
    {
        LOG("ERROR", "In async_post mutex unlock failed");
        ret = false;
    }

    return ret;
    
}

// blocking
static bool async_get(async_q_t* q, void* elem)
{
    bool ret = true;
    if(pthread_mutex_lock(&(q->lock)))
    {
        LOG("ERROR", "In async_get mutex lock failed");
        return false;
    }

    while(q->n == 0)
    {
        if(pthread_cond_wait(&(q->getter_cv), &(q->lock)))
        {
            LOG("ERROR", "In async_get cond wait failed");
        }
    }

    memcpy(elem, q->q + (((q->n)-1)* (q->element_size)), q->element_size);
    --(q->n);

    if(pthread_cond_signal(&(q->poster_cv)))
    {
        LOG("ERROR", "In async_get cond signal failed");
        ret = false;
    }

    if(pthread_mutex_unlock(&(q->lock)))
    {
        LOG("ERROR", "In async_get mutex unlock failed");
        ret = false;
    }

    return ret;

}

static void* _async_thread_func(void* args)
{
    async_runner_t* me = (async_runner_t*) args;
    uint8_t elem[me->q->element_size];

    LOG("INFO", "Async Runner %d starting", me->thread_num);

    while(!(me->killed))
    {
        if(!async_get(me->q, (void*) &elem))
        {
            LOG("ERROR", "In async_runner %d async_get failed");
        }

        if(me->killed)
        {
            break;
        }

        me->consume((void*) &elem);
    }

    LOG("INFO", "Async Runner %d killed", me->thread_num);
    return NULL;
}


static bool async_launch_runners(async_runner_t* runners, 
                          uint16_t n_runners,
                          async_q_t* alloced_queue,
                          async_consumer_t consumer_func)
{

    if(n_runners >= alloced_queue->n_max)
    {
        LOG("ERROR", "In async_launch_runners we do not allow there to be more runners than the size of the queue");
        return false;
    }

    uint16_t i;
    for(i = 0; i < n_runners; ++i)
    {
        async_runner_t* runner = &(runners[i]) ;

        runner->thread_num = i;
        runner->consume = consumer_func;
        runner->q = alloced_queue;
        runner->killed = false;
        runner->n_runners = n_runners;

        if( pthread_create(&(runner->pthread), 
                       NULL, 
                       _async_thread_func,
                       (void*) runner)
        )
        {
            LOG("ERROR", "In async_launch_runners pthread create failed");
            return false;
        }
    }

    return true;

}

static bool async_kill_runners(async_runner_t* runners)
{
    uint16_t i;
    uint16_t n_runners = runners[0].n_runners;
    bool ret = true;

    for(i = 0; i < n_runners; ++i)
    {
        runners[i].killed = true;
    }

    for(i = 0; i < n_runners; ++i)
    {
        uint8_t elem[runners[i].q->element_size];
        if(!async_post((runners[i].q), elem))
        {
            LOG("ERROR", "In async_kill_runners Failed to post");
            ret = false;
        }
    }

    for(i = 0; i < n_runners; ++i)
    {
        if(pthread_join((runners[i].pthread), NULL))
        {
            LOG("ERROR", "In async_kill_runners Failed to join");
            ret = false;
        }
    }

    return ret;

}

static bool check_off[1000] = {0};

static void consumer(void* args)
{
    int arg = *((int*) args);

    if(check_off[arg])
    {
        LOG("ERROR", "TEST FAILED - duplicate elements: %d", arg);
    }
    else
    {
        check_off[arg] = true;
    }
}

static void async_q_test()
{
    uint16_t n_runners = 3;
    uint32_t n_elem = 10;
    async_q_t q;
    async_runner_t runners[n_runners];
    uint32_t i;

    async_q_create(&q, sizeof(int), n_elem);
    async_launch_runners(runners, n_runners, &q, consumer);

    for(i = 0; i < 1000; ++i)
    {
        async_post(&q, (void*) (&i));
    }

    sleep(1);


    for(i = 0; i < 1000; ++i)
    {
        if(check_off == false)
        {
            LOG("ERROR", "TEST FAILED - elem not consumed");
            break;
        }
    }

    LOG("INFO", "TEST PASSED");

    async_kill_runners(runners);
    aysnc_q_destroy(&q);

}

