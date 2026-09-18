/**
 * cipher.c - Legacy DES and symmetric block cipher routines.
 */

#include <stdio.h>
#include <string.h>

void DES_set_key(const void *key, void *schedule);
void DES_ecb_encrypt(const void *input, void *output, void *schedule, int enc);
void RC4_set_key(void *key, int len, const unsigned char *data);

int encrypt_legacy_session_token(const unsigned char *token, unsigned char *out_cipher) {
    unsigned char key[8] = {0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef};
    unsigned char schedule[128];

    DES_set_key(key, schedule);
    DES_ecb_encrypt(token, out_cipher, schedule, 1);

    return 8;
}
