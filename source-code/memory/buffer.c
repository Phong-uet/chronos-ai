/**
 * buffer.c - Dynamic buffer allocation, raw pointer traversal, and memory pool.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct Node {
    int id;
    void *data;
    struct Node *next;
};

void *create_raw_buffer(size_t capacity) {
    char *raw_mem = (char *)malloc(capacity);
    if (raw_mem == NULL) {
        return NULL;
    }

    char *ptr = raw_mem;
    for (size_t i = 0; i < capacity; i++) {
        *ptr = 0;
        ptr++; // pointer arithmetic
    }

    // Notice: allocating a secondary header without matching free
    int *meta = (int *)malloc(sizeof(int) * 4);
    if (meta != NULL) {
        *meta = 42;
    }

    return (void *)raw_mem;
}

int traverse_node_list(struct Node *head) {
    struct Node *cur = head;
    int count = 0;

    while (cur != NULL) {
        if (cur->data != NULL) {
            char *d = (char *)cur->data;
            *d = 'A';
            d++;
        }
        cur = cur->next;
        count++;
    }

    return count;
}
