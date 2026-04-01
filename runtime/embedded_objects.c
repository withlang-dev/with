// Embedded runtime object files for self-contained linking.
// Generated data is included from embedded_objects.inc.h.

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

typedef struct { const char *ptr; int64_t len; } with_str;

#include "../out/lib/embedded_objects.inc.h"

#define MATCH(s, lit) (s.len == sizeof(lit)-1 && memcmp(s.ptr, lit, sizeof(lit)-1) == 0)

// Write embedded object to a file path. Returns 0 on success.
int32_t with_extract_runtime_obj(with_str name, with_str path) {
    const unsigned char *data = NULL;
    int len = 0;

    if (MATCH(name, "helpers.o")) {
        data = helpers_o; len = helpers_o_len;
    } else if (MATCH(name, "support_runtime.o")) {
        data = support_runtime_o; len = support_runtime_o_len;
    } else if (MATCH(name, "with_runtime.o")) {
        data = with_runtime_o; len = with_runtime_o_len;
    } else if (MATCH(name, "fiber.o")) {
        data = fiber_o; len = fiber_o_len;
    } else if (MATCH(name, "fiber_asm.o")) {
        data = fiber_asm_o; len = fiber_asm_o_len;
    } else if (MATCH(name, "rt_core.o")) {
        data = rt_core_o; len = rt_core_o_len;
    } else if (MATCH(name, "rt_darwin_aarch64.o")) {
        data = rt_darwin_aarch64_o; len = rt_darwin_aarch64_o_len;
    }

    if (data == NULL || len == 0) return 1;

    // Write to null-terminated path
    char pathbuf[4096];
    int64_t plen = path.len < 4095 ? path.len : 4095;
    memcpy(pathbuf, path.ptr, (size_t)plen);
    pathbuf[plen] = 0;

    FILE *f = fopen(pathbuf, "wb");
    if (!f) return 1;
    size_t written = fwrite(data, 1, (size_t)len, f);
    fclose(f);
    return written == (size_t)len ? 0 : 1;
}
