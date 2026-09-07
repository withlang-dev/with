#include <stdio.h>
#include <stdint.h>
int main(void) {
    int64_t v = ((int64_t)1 << 33) | 3;  // high bits set
    int64_t n = 1;
    // exact expression CCodegen emits for i64 rotate_left:
    int64_t got = (int64_t)({ uint32_t __with_v = (uint32_t)(v); uint32_t __with_n = (uint32_t)(n) & 31u; (int32_t)((__with_v << __with_n) | (__with_v >> (32u - __with_n))); });
    // correct 64-bit rotate:
    uint64_t uv = (uint64_t)v;
    int64_t want = (int64_t)((uv << 1) | (uv >> 63));
    printf("got=%lld want=%lld\n", (long long)got, (long long)want);
    return got != want;
}
