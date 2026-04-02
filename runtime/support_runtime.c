#include "with_runtime.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

__attribute__((weak)) void with_runtime_init(void) {
}

__attribute__((weak)) void with_runtime_run(void) {
}

__attribute__((weak)) void with_runtime_shutdown(void) {
}

__attribute__((weak)) void with_fiber_yield(void) {
}

__attribute__((weak)) int32_t with_fiber_in_fiber(void) {
    return 0;
}

__attribute__((weak)) int32_t with_fiber_is_cancelled(void) {
    return 0;
}

__attribute__((weak)) void with_fiber_panic_capture(const char *msg, int32_t msg_len) {
    (void)msg; (void)msg_len;
    // Fallback: if fiber.o not linked, just abort
    abort();
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

void print(with_str s) {
    with_print_str(s);
}

void with_assert(bool cond, const char *msg, const char *file, int line) {
    if (!cond) {
        fprintf(stderr, "assertion failed: %s at %s:%d\n", msg, file, line);
        abort();
    }
}

// Fiber panic hook: set by fiber.c's with_runtime_init to enable panic capture.
// When NULL, panics abort normally. When set, called to capture panic in fiber.
void (*with_fiber_panic_hook)(const char *msg, int32_t msg_len) = NULL;
int32_t (*with_fiber_in_fiber_hook)(void) = NULL;

void with_panic(with_str msg, with_str file, int32_t line) {
    // If inside a fiber, capture the panic instead of aborting.
    if (with_fiber_in_fiber_hook && with_fiber_in_fiber_hook()) {
        if (with_fiber_panic_hook) {
            char buf[512];
            int len = 0;
            if (file.len > 0) {
                len = snprintf(buf, sizeof(buf), "panic at %.*s:%d: %.*s",
                              (int)file.len, file.ptr, (int)line,
                              (int)msg.len, msg.ptr);
            } else {
                len = snprintf(buf, sizeof(buf), "panic: %.*s",
                              (int)msg.len, msg.ptr);
            }
            if (len < 0) len = 0;
            if (len >= (int)sizeof(buf)) len = (int)sizeof(buf) - 1;
            with_fiber_panic_hook(buf, (int32_t)len);
            __builtin_unreachable();
        }
    }
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
