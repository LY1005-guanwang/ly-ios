#ifndef LY_BRIDGING_HEADER_H
#define LY_BRIDGING_HEADER_H
#include <stddef.h>
unsigned char *ly_inflate_raw(const unsigned char *in, size_t inLen, size_t *outLen);
unsigned char *ly_inflate_zlib(const unsigned char *in, size_t inLen, size_t *outLen);
#endif