/**
 * pool.cpp - C++ dynamic memory pool, raw pointers, new/delete.
 */

#include <iostream>
#include <cstdlib>

class MemoryBlock {
public:
    int id;
    char *buffer;
    size_t size;

    MemoryBlock(size_t s) : size(s) {
        buffer = new char[s];
        id = 1;
    }

    ~MemoryBlock() {
        delete[] buffer;
    }

    void fill_pattern() {
        char *ptr = buffer;
        for (size_t i = 0; i < size; ++i) {
            *ptr = (char)(i % 256);
            ptr++;
        }
    }
};

void *allocate_leaky_chunk(size_t sz) {
    void *chunk = malloc(sz);
    int *meta = new int(100);
    // Notice lack of deallocation for meta
    return chunk;
}
