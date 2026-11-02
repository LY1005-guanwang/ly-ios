#include <zlib.h>
#include <stdlib.h>
#include <string.h>

// raw deflate (-15) 解压；成功返回 malloc 缓冲（调用方 free），长度写入 *outLen
unsigned char *ly_inflate_raw(const unsigned char *in, size_t inLen, size_t *outLen) {
    if (!in || inLen == 0) return NULL;
    if (outLen) *outLen = 0;
    z_stream s;
    memset(&s, 0, sizeof(s));
    if (inflateInit2(&s, -15) != Z_OK) return NULL;

    size_t cap = inLen * 4 + 2048;
    size_t len = 0;
    unsigned char *out = (unsigned char *)malloc(cap);
    if (!out) { inflateEnd(&s); return NULL; }

    s.next_in = (Bytef *)in;
    s.avail_in = (uInt)inLen;
    int ret;
    do {
        if (len == cap) {
            cap *= 2;
            unsigned char *n = (unsigned char *)realloc(out, cap);
            if (!n) { free(out); inflateEnd(&s); return NULL; }
            out = n;
        }
        s.next_out = out + len;
        s.avail_out = (uInt)(cap - len);
        ret = inflate(&s, Z_NO_FLUSH);
        len = cap - s.avail_out;
        if (ret == Z_STREAM_ERROR || ret == Z_DATA_ERROR || ret == Z_MEM_ERROR) {
            free(out); inflateEnd(&s); return NULL;
        }
    } while (ret != Z_STREAM_END);

    inflateEnd(&s);
    if (outLen) *outLen = len;
    return out;
}