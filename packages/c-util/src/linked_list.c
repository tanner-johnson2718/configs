#include "linked_list.h"
#include <stdio.h>
#include <stdlib.h>

ll_err_t ll_print(ll_t* ll)
{
    if(ll == NULL)
    {
        return BAD_ARGS;
    }

    node_t* n = ll->head;
    if(n == NULL)
    {
        printf("List Empty!!\n");
        return LIST_EMPTY;
    }

    char line[TO_STRING_LINE_BUFFER_SIZE];

    printf("Num Nodes = %d\n", ll->num_nodes);
    printf("Head      = %p\n", ll->head);
    printf("Tail      = %p\n", ll->tail);
    printf("\n");

    printf("--------------------------------------------------------------------------------\n");
    printf("|        Node       |        Next       |       Prev       |       Data        |\n");
    printf("--------------------------------------------------------------------------------\n");
    while(n != ll->tail)
    {
        ll->to_string(n->data, line);
        
        printf("|  %15p  |  %15p  |  %14p  |  %15s  |\n", n, n->next, n->prev, line);

        n = n->next;
    }
    ll->to_string(n->data, line);
    printf("|  %15p  |  %15p  |  %14p  |  %15s  |\n", n, n->next, n->prev, line);
    printf("--------------------------------------------------------------------------------\n");
    return SUCCESS;
}

ll_err_t ll_query(ll_t* ll, void* data, node_t** ret)
{
    if(ll == NULL || ret == NULL)
    {
        return BAD_ARGS;
    }

    if(ll->head == NULL)
    {
        return LIST_EMPTY;
    }

    node_t* n = ll->head;
    while(n != ll->tail)
    {
        if(ll->comp(data, n->data) == 0)
        {
            break;
        }
        n = n->next;
    }

    if(ll->comp(data, n->data) != 0)
    {
        *ret = NULL;
        return NODE_NOT_FOUND;
    }

    *ret = n;
    return SUCCESS;
}

ll_err_t ll_remove(ll_t* ll, node_t* node)
{
    if(ll == NULL || node == NULL)
    {
        return BAD_ARGS;
    }

    if(ll->head == NULL)
    {
        return LIST_EMPTY;
    }

    if(node == ll->head)
    {
        ll->head = node->next;
    }
    if(node == ll->tail)
    {
        ll->tail = node->prev;
    }
    if(node->next != NULL)
    {
        node->next->prev = node->prev;
    }
    if(node->prev != NULL)
    {
        node->prev->next = node->next;
    }

    --(ll->num_nodes);
    free(node);
    return SUCCESS;
}

ll_err_t ll_free_all(ll_t* ll)
{
    if(ll == NULL)
    {
        return BAD_ARGS;
    }

    if(ll->head == NULL)
    {
        return LIST_EMPTY;
    }

    while(1)
    {
        ll_err_t err = ll_remove(ll, ll->head);
        if(err != SUCCESS)
        {
            break;
        }
    }

    return SUCCESS;
}


ll_err_t ll_create(ll_t* alloced_ll, comparator_t comp, to_string_t to_string)
{
    alloced_ll->head = NULL;
    alloced_ll->tail = NULL;
    alloced_ll->comp = comp;
    alloced_ll->to_string = to_string;
    alloced_ll->num_nodes = 0;
    return SUCCESS;
}

ll_err_t ll_put_tail(ll_t* ll, void* data)
{
    if(ll == NULL)
    {
        return BAD_ARGS;
    }

    node_t* new = malloc(sizeof(node_t));
    if(new == NULL)
    {
        return OUT_OF_MEM;
    }

    new->next = NULL;
    new->prev = ll->tail;
    new->data = data;

    if(ll->head == NULL)     // First element inserted
    {
        ll->head = new;
        ll->tail = new;
    }
    else                    // 2nd+ element inserted
    {
        ll->tail->next = new;
        ll->tail = new;
    }

    ++(ll->num_nodes);
    return SUCCESS;
}

ll_err_t ll_put_head(ll_t* ll, void* data)
{
    if(ll == NULL)
    {
        return BAD_ARGS;
    }

    node_t* new = malloc(sizeof(node_t));
    if(new == NULL)
    {
        return OUT_OF_MEM;
    }

    new->prev = NULL;
    new->next = ll->head;
    new->data = data;

    if(ll->head == NULL)     // First element inserted
    {
        ll->head = new;
        ll->tail = new;
    }
    else                    // 2nd+ element inserted
    {
        ll->head->prev = new;
        ll->head = new;
    }

    ++(ll->num_nodes);
    return SUCCESS;
}

ll_err_t ll_pop_head(ll_t* ll, void** ret)
{
    if(ll == NULL || ret == NULL)
    {
        return BAD_ARGS;
    }

    if(ll->head == NULL)
    {
        return LIST_EMPTY;
    }

    *ret = ll->head->data;
    ll_err_t err = ll_remove(ll, ll->head);
    if(err != SUCCESS)
    {
        return UNKNOWN_ERR;
    }

    return SUCCESS;
}

ll_err_t ll_pop_tail(ll_t* ll, void** ret)
{
    if(ll == NULL || ret == NULL)
    {
        return BAD_ARGS;
    }

    if(ll->head == NULL)
    {
        return LIST_EMPTY;
    }

    *ret = ll->tail->data;
    ll_err_t err = ll_remove(ll, ll->tail);
    if(err != SUCCESS)
    {
        return UNKNOWN_ERR;
    }

    return SUCCESS;
}
