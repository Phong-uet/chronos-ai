/**
 * packet.h - Network packet headers with struct alignment padding.
 */

#ifndef PACKET_H
#define PACKET_H

#include <stdint.h>

// Struct with deliberate alignment padding (char before double and int)
struct PacketHeader {
    char protocol_tag;       // 1 byte + 7 bytes padding
    double timestamp;        // 8 bytes
    int payload_length;      // 4 bytes + 4 bytes tail padding -> 24 bytes total
};

struct PacketPayload {
    char flag;               // 1 byte + 7 bytes padding
    void *buffer_ptr;        // 8 bytes (pointer)
    int status_code;         // 4 bytes + 4 bytes padding -> 24 bytes total
};

struct MemoryChunk {
    int chunk_id;
    char flags[3];
    long total_size;
    void *raw_data;
};

#endif // PACKET_H
