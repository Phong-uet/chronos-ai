/**
 * rsa.c - Legacy RSA and DES asymmetric/symmetric key routines.
 */

#include <stdio.h>
#include <stdlib.h>

typedef struct rsa_st RSA;

RSA *RSA_generate_key(int bits, unsigned long e, void (*callback)(int, int, void *), void *cb_arg);
int RSA_public_encrypt(int flen, const unsigned char *from, unsigned char *to, RSA *rsa, int padding);
int RSA_private_encrypt(int flen, const unsigned char *from, unsigned char *to, RSA *rsa, int padding);
void DES_set_key(const void *key, void *schedule);

int generate_legacy_rsa_keypair(int key_size_bits) {
    if (key_size_bits < 1024) {
        printf("Warning: Insecure RSA key length requested\n");
    }

    RSA *key = RSA_generate_key(key_size_bits, 65537, NULL, NULL);
    if (key == NULL) {
        return -1;
    }

    unsigned char input[128] = "Legacy handshake token";
    unsigned char encrypted[256];

    int encrypted_len = RSA_public_encrypt(22, input, encrypted, key, 1);
    return encrypted_len;
}
