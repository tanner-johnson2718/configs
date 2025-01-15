#include "linked_list.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

int comp(void* d1, void* d2)
{
    int _d1 = *((int*)d1);
    int _d2 = *((int*)d2);
    return _d1-_d2;
}

void to_string(void* d, char* buff)
{
    sprintf(buff, "%d", *(int*)d);
}

// Insert and delete visual incpection
void test0()
{
    ll_t* ll = malloc(sizeof(ll_t));
    assert(ll);

    int x0 = 0;
    int x1 = 1;
    int x3 = 3;
    int x2 = 2;

    node_t* node;

    // Create the ll and insert the 4 elements. Assert each op is a success.
    // Do some check at the end to ensure the linked has the proper topo
    ll_err_t err = ll_create(ll, comp, to_string);
    assert(err == SUCCESS);
    err = ll_put_tail(ll, (void*) &x0);
    assert(err == SUCCESS);
    err = ll_put_tail(ll, (void*) &x1);
    assert(err == SUCCESS);
    err = ll_put_tail(ll, (void*) &x2);
    assert(err == SUCCESS);
    err = ll_put_tail(ll, (void*) &x3);
    assert(err == SUCCESS);
    err = ll_print(ll);
    assert(err == SUCCESS);
    assert(ll->num_nodes == 4);
    assert(ll->head != NULL);
    assert(ll->head->data == &x0);
    assert(ll->tail != NULL);
    assert(ll->tail->next == NULL);
    assert(ll->tail->prev->data == &x2);

    // Ensure that when we delete a node that a query fails and the proper
    // pointers have been updated
    err = ll_query(ll, &x0, &node);
    assert(err == SUCCESS);
    err = ll_remove(ll, node);
    assert(err == SUCCESS);
    err = ll_print(ll);
    err = ll_query(ll, &x0, &node);
    assert(err == NODE_NOT_FOUND);
    assert(ll->head != NULL);
    assert(ll->head->data == &x1);
    assert(ll->head->next->data == &x2);
    assert(ll->head->next->prev->data == &x1);
    
    // Delete middle node, ensure 1 and 3 point to each other and 
    err = ll_query(ll, &x2, &node);
    assert(err == SUCCESS);
    err = ll_remove(ll, node);
    assert(err == SUCCESS);
    err = ll_print(ll);
    assert(ll->head != NULL);
    assert(ll->head->data == &x1);
    assert(ll->tail != NULL);
    assert(ll->tail->data == &x3);
    assert(ll->head->next->data == &x3);
    assert(ll->head->prev == NULL);
    assert(ll->tail->prev->data == &x1);
    assert(ll->tail->next == NULL);

    // delete head, leaving one element
    err = ll_query(ll, &x1, &node);
    assert(err == SUCCESS);
    err = ll_remove(ll, node);
    assert(err == SUCCESS);
    err = ll_print(ll);
    assert(ll->head == ll->tail);
    assert(ll->head != NULL);
    assert(ll->head->data == &x3);
    assert(ll->head->next == NULL);
    assert(ll->head->prev == NULL);

    // remove last one, ensure list is properly returned to init state
    err = ll_query(ll, &x3, &node);
    err = ll_remove(ll, node);
    err = ll_print(ll);
    assert(ll->head == NULL);
    assert(ll->tail == NULL);
    assert(ll->num_nodes == 0);

    // free_all(ll);
    free(ll);
}

// free_all test
void test1()
{
    ll_t* ll = malloc(sizeof(ll_t));
    assert(ll);

    int x0 = 0;
    int x1 = 1;
    int x3 = 3;
    int x2 = 2;

    node_t* node;

    ll_err_t err = ll_create(ll, comp, to_string);
    err = ll_put_tail(ll, (void*) &x0);
    err = ll_put_tail(ll, (void*) &x1);
    err = ll_put_tail(ll, (void*) &x2);
    err = ll_put_tail(ll, (void*) &x3);
    err = ll_free_all(ll);

    assert(ll->head == NULL);
    assert(ll->tail == NULL);
    assert(ll->num_nodes == 0);

    free(ll);
}

// Test succesive inserts at head
void test2()
{
    ll_t* ll = malloc(sizeof(ll_t));
    assert(ll);

    int x0 = 0;
    int x1 = 1;
    int x3 = 3;
    int x2 = 2;

    node_t* node;

    ll_err_t err = ll_create(ll, comp, to_string);
    err = ll_put_head(ll, (void*) &x0);
    err = ll_put_head(ll, (void*) &x1);
    err = ll_put_head(ll, (void*) &x2);
    err = ll_put_head(ll, (void*) &x3);
    assert(ll->head->data == &x3);
    assert(ll->tail->data == &x0);
    assert(ll->head->next->data == &x2);
    assert(ll->tail->prev->data == &x1);

    err = ll_free_all(ll);

    free(ll);
}

// Test pops
void test3()
{
    ll_t* ll = malloc(sizeof(ll_t));
    assert(ll);

    int x0 = 0;
    int x1 = 1;
    int x3 = 3;
    int x2 = 2;

    node_t* node;

    ll_err_t err = ll_create(ll, comp, to_string);
    err = ll_put_head(ll, (void*) &x0);
    err = ll_put_head(ll, (void*) &x1);
    err = ll_put_head(ll, (void*) &x2);
    err = ll_put_head(ll, (void*) &x3);
    ll_print(ll);

    int* ret;
    err = ll_pop_head(ll, (void**) &ret);
    assert(*ret == x3);
    err = ll_pop_tail(ll, (void**) &ret);
    assert(*ret == x0);

    ll_free_all(ll);
    free(ll);
}

int main()
{
    test0();
    test1();
    test2();
    test3();
}