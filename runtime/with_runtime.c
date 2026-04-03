// With Language C runtime shim for `--emit-c`.
//
// helpers.c owns the bulk runtime surface. This file only provides the small
// lifecycle/panic layer that emitted C still needs.

#include "with_runtime.h"

#include <stdio.h>
#include <stdlib.h>

extern void with_fiber_panic_capture(const char *msg, int32_t msg_len);

__attribute__((weak)) void with_runtime_init(void) {
}

__attribute__((weak)) void with_runtime_run(void) {
}

__attribute__((weak)) void with_runtime_shutdown(void) {
}

__attribute__((weak)) int32_t with_fiber_is_cancelled(void) {
    return 0;
}

void with_assert(bool cond, const char *msg, const char *file, int line) {
    if (!cond) {
        fprintf(stderr, "assertion failed: %s at %s:%d\n", msg, file, line);
        abort();
    }
}

void with_panic(with_str msg, with_str file, int32_t line) {
    if (with_fiber_in_fiber()) {
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
        with_fiber_panic_capture(buf, (int32_t)len);
        abort();
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
