#include "with_runtime.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

__attribute__((weak)) void with_runtime_init(void) {
}

__attribute__((weak)) void with_runtime_shutdown(void) {
}

with_str with_str_from_cstr(const char *s) {
    with_str out;
    if (!s) {
        out.ptr = "";
        out.len = 0;
    } else {
        out.ptr = s;
        out.len = (int64_t)strlen(s);
    }
    return out;
}

with_str with_i64_to_str(int64_t n) {
    char tmp[32];
    int wrote = snprintf(tmp, sizeof(tmp), "%lld", (long long)n);
    if (wrote <= 0) {
        with_str out = {"", 0};
        return out;
    }
    char *buf = (char *)malloc((size_t)wrote + 1);
    if (!buf) {
        with_str out = {"", 0};
        return out;
    }
    memcpy(buf, tmp, (size_t)wrote + 1);
    with_str out = {buf, (int64_t)wrote};
    return out;
}

with_str with_bool_to_str(bool b) {
    if (b) return WITH_STR_LIT("true");
    return WITH_STR_LIT("false");
}

void with_println_str(with_str s) {
    if (s.len > 0) {
        fwrite(s.ptr, 1, (size_t)s.len, stdout);
    }
    fputc('\n', stdout);
}

void with_println_i32(int32_t n) {
    printf("%d\n", n);
}

void with_println_i64(int64_t n) {
    printf("%lld\n", (long long)n);
}

void with_println_bool(bool b) {
    printf("%s\n", b ? "true" : "false");
}

void with_print_str(with_str s) {
    if (s.len > 0) {
        fwrite(s.ptr, 1, (size_t)s.len, stdout);
    }
}

void with_assert(bool cond, const char *msg, const char *file, int line) {
    if (!cond) {
        fprintf(stderr, "assertion failed: %s at %s:%d\n", msg, file, line);
        abort();
    }
}

void with_panic(with_str msg, with_str file, int32_t line) {
    if (file.len > 0) {
        fprintf(stderr, "panic at %.*s:%d: ", (int)file.len, file.ptr, (int)line);
    } else {
        fprintf(stderr, "panic: ");
    }
    if (msg.len > 0) {
        fwrite(msg.ptr, 1, (size_t)msg.len, stderr);
    }
    fputc('\n', stderr);
    abort();
}
