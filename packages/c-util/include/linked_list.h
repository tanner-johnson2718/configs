#pragma once

#include <stdint.h>

#define TO_STRING_LINE_BUFFER_SIZE 16

typedef struct node_s
{
    void* data;
    struct node_s* next;
    struct node_s* prev;
} node_t;

// Comparator function that returns 0 if equal and may return negative if 
// d1 < d2 and positive if d2 < d1.
typedef int (*comparator_t)(void* d1, void* d2);

// ToString function so we can print the objects in the list
typedef void (*to_string_t)(void* d, char* b);

// Linked list data structure. Maybe in the future make the doubly linked 
// portion a macro flag but for now is explixitly a doubly linked list.
typedef struct
{
    node_t* head;
    node_t* tail;
    uint32_t num_nodes;
    comparator_t comp;
    to_string_t to_string;
} ll_t;

typedef enum
{
    SUCCESS = 0,
    OUT_OF_MEM,
    UNKNOWN_ERR,
    NOT_IMPL,
    LIST_EMPTY,
    NODE_NOT_FOUND,
    BAD_ARGS
} ll_err_t;

ll_err_t ll_create(ll_t* alloced_ll, comparator_t comp, to_string_t to_string);
ll_err_t ll_remove(ll_t* ll, node_t* node);
ll_err_t ll_query(ll_t* ll, void* data, node_t** ret);
ll_err_t ll_free_all(ll_t* ll);
ll_err_t ll_print(ll_t* ll);

// Include some convience functions for using the data structure as a stack or
// double ended queue
ll_err_t ll_pop_head(ll_t* ll, void** ret);
ll_err_t ll_pop_tail(ll_t* ll, void** ret);
ll_err_t ll_put_tail(ll_t* ll, void* data);
ll_err_t ll_put_head(ll_t* ll, void* data);
