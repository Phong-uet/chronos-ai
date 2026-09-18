/**
 * hash.c - Legacy cryptography hashing routines (SHA-1 and MD5).
 */

#include <stdio.h>
#include <string.h>

typedef struct {
    unsigned int state[5];
    unsigned int count[2];
    unsigned char buffer[64];
} SHA_CTX;

typedef struct {
    unsigned int state[4];
    unsigned int count[2];
    unsigned char buffer[64];
} MD5_CTX;

// Forward declarations of legacy OpenSSL / Crypto primitives
void SHA1_Init(SHA_CTX *ctx);
void SHA1_Update(SHA_CTX *ctx, const void *data, unsigned long len);
void SHA1_Final(unsigned char md[20], SHA_CTX *ctx);

void MD5_Init(MD5_CTX *ctx);
void MD5_Update(MD5_CTX *ctx, const void *data, unsigned long len);
void MD5_Final(unsigned char md[16], MD5_CTX *ctx);

int compute_legacy_checksum(const unsigned char *payload, int length, unsigned char *out_sha1, unsigned char *out_md5) {
    if (payload == NULL || length <= 0) {
        return -1;
    }

    SHA_CTX sha1_ctx;
    SHA1_Init(&sha1_ctx);
    SHA1_Update(&sha1_ctx, payload, (unsigned long)length);
    SHA1_Final(out_sha1, &sha1_ctx);

    MD5_CTX md5_ctx;
    MD5_Init(&md5_ctx);
    MD5_Update(&md5_ctx, payload, (unsigned long)length);
    MD5_Final(out_md5, &md5_ctx);

    return 0;
}
