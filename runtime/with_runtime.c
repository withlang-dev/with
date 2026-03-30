// With Language C Runtime — Implementation
// Provides Vec, string ops, I/O, and assert for the C backend.

#include "with_runtime.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Weak lifecycle stubs; fiber.c provides strong definitions.
__attribute__((weak)) void with_runtime_init(void) {
}

__attribute__((weak)) void with_runtime_shutdown(void) {
}

// ── String operations ──────────────────────────────────────────────

with_str with_str_concat(with_str a, with_str b) {
    int64_t total = a.len + b.len;
    char *buf = (char *)malloc((size_t)total + 1);
    if (!buf) {
        with_str out = {"", 0};
        return out;
    }
    if (a.len > 0) memcpy(buf, a.ptr, (size_t)a.len);
    if (b.len > 0) memcpy(buf + a.len, b.ptr, (size_t)b.len);
    buf[total] = '\0';
    with_str out = {buf, total};
    return out;
}

bool with_str_eq(with_str a, with_str b) {
    if (a.len != b.len) return false;
    if (a.len == 0) return true;
    return memcmp(a.ptr, b.ptr, (size_t)a.len) == 0;
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
    memcpy(buf, tmp, (size_t)wrote + 1);
    with_str out = {buf, (int64_t)wrote};
    return out;
}

with_str with_bool_to_str(bool b) {
    if (b) return WITH_STR_LIT("true");
    return WITH_STR_LIT("false");
}

__attribute__((weak)) int64_t with_parse_i64(with_str s) {
    if (!s.ptr || s.len <= 0) return 0;
    char *buf = (char *)malloc((size_t)s.len + 1);
    if (!buf) return 0;
    memcpy(buf, s.ptr, (size_t)s.len);
    buf[s.len] = '\0';
    long long v = atoll(buf);
    free(buf);
    return (int64_t)v;
}

// ── Vec operations ─────────────────────────────────────────────────

// Compatibility shim:
// - Correct C ABI callers pass a hidden sret pointer in x8.
// - Some selfhost-generated callers in this branch expect register returns.
// Support both on arm64 to keep stage transitions runnable.
#if defined(__aarch64__)
__attribute__((naked)) with_vec with_vec_new(int64_t elem_size) {
    __asm__ volatile(
        "mov x9, x0\n"
        "mov x0, xzr\n"
        "mov x1, xzr\n"
        "mov x2, xzr\n"
        "mov x3, x9\n"
        "ret\n");
}
#else
with_vec with_vec_new(int64_t elem_size) {
    with_vec v;
    v.ptr = NULL;
    v.len = 0;
    v.cap = 0;
    v.elem_size = elem_size;
    return v;
}
#endif

__attribute__((weak)) void with_vec_new_out(with_vec *out, int64_t elem_size) {
    if (!out) return;
    *out = with_vec_new(elem_size);
}

__attribute__((weak)) void with_vec_new_with_capacity_out(with_vec *out, int64_t elem_size, int64_t capacity) {
    if (!out) return;
    out->len = 0;
    out->cap = capacity;
    out->elem_size = elem_size;
    if (capacity > 0) {
        out->ptr = malloc((size_t)(capacity * elem_size));
        if (!out->ptr) { fprintf(stderr, "with: out of memory in vec with_capacity\n"); abort(); }
    } else {
        out->ptr = NULL;
    }
}

static void with_vec_grow(with_vec *v) {
    int64_t new_cap = v->cap == 0 ? 8 : v->cap * 2;
    void *new_ptr = realloc(v->ptr, (size_t)(new_cap * v->elem_size));
    if (!new_ptr) {
        fprintf(stderr, "with: out of memory in vec grow\n");
        abort();
    }
    v->ptr = new_ptr;
    v->cap = new_cap;
}

void with_vec_push(with_vec *v, const void *elem) {
    if (v->len >= v->cap) {
        with_vec_grow(v);
    }
    memcpy((char *)v->ptr + v->len * v->elem_size, elem, (size_t)v->elem_size);
    v->len++;
}

void *with_vec_get_ptr(with_vec *v, int64_t index) {
    return (char *)v->ptr + index * v->elem_size;
}

int64_t with_vec_len(with_vec *v) {
    return v->len;
}

void with_vec_clear(with_vec *v) {
    v->len = 0;
}

void with_vec_push_i32(with_vec *v, int32_t val) {
    with_vec_push(v, &val);
}

int32_t with_vec_get_i32(with_vec *v, int64_t index) {
    return *(int32_t *)with_vec_get_ptr(v, index);
}

int32_t with_ptr_get_i32(void *ptr, int64_t index) {
    return ((int32_t *)ptr)[index];
}

void with_vec_push_i64(with_vec *v, int64_t val) {
    with_vec_push(v, &val);
}

int64_t with_vec_get_i64(with_vec *v, int64_t index) {
    return *(int64_t *)with_vec_get_ptr(v, index);
}

void with_vec_push_str(with_vec *v, with_str val) {
    with_vec_push(v, &val);
}

with_str with_vec_get_str(with_vec *v, int64_t index) {
    return *(with_str *)with_vec_get_ptr(v, index);
}

__attribute__((weak)) void with_lines_out(with_vec *out, with_str s) {
    if (!out) return;
    with_vec_new_out(out, (int64_t)sizeof(with_str));
    if (!s.ptr || s.len < 0) return;

    int64_t start = 0;
    for (int64_t i = 0; i <= s.len; i++) {
        if (i == s.len || s.ptr[i] == '\n') {
            with_str part = {s.ptr + start, i - start};
            with_vec_push_str(out, part);
            start = i + 1;
        }
    }
}

void with_vec_push_bool(with_vec *v, bool val) {
    with_vec_push(v, &val);
}

bool with_vec_get_bool(with_vec *v, int64_t index) {
    return *(bool *)with_vec_get_ptr(v, index);
}

void with_vec_set_i32(with_vec *v, int64_t index, int32_t val) {
    if (index >= 0 && index < v->len) {
        ((int32_t *)v->ptr)[index] = val;
    }
}

void with_vec_set_i64(with_vec *v, int64_t index, int64_t val) {
    if (index >= 0 && index < v->len) {
        ((int64_t *)v->ptr)[index] = val;
    }
}

void with_vec_remove(with_vec *v, int64_t index) {
    if (index < 0 || index >= v->len) return;
    char *base = (char *)v->ptr;
    int64_t es = v->elem_size;
    memmove(base + index * es, base + (index + 1) * es, (v->len - index - 1) * es);
    v->len--;
}

with_option_i32 with_vec_pop_i32(with_vec *v) {
    with_option_i32 r;
    if (v->len <= 0) {
        r.has_value = false;
        r.value = 0;
        return r;
    }
    v->len--;
    r.has_value = true;
    r.value = ((int32_t *)v->ptr)[v->len];
    return r;
}

#define WITH_CODEGEN_LOOP_MAX 1024
static int64_t with_codegen_loop_break_bbs[WITH_CODEGEN_LOOP_MAX];
static int64_t with_codegen_loop_continue_bbs[WITH_CODEGEN_LOOP_MAX];
static int64_t with_codegen_loop_result_vals[WITH_CODEGEN_LOOP_MAX];

void with_codegen_loop_set_break(int32_t idx, int64_t bb) {
    if (idx < 0 || idx >= WITH_CODEGEN_LOOP_MAX) return;
    with_codegen_loop_break_bbs[idx] = bb;
}

void with_codegen_loop_set_continue(int32_t idx, int64_t bb) {
    if (idx < 0 || idx >= WITH_CODEGEN_LOOP_MAX) return;
    with_codegen_loop_continue_bbs[idx] = bb;
}

void with_codegen_loop_set_result(int32_t idx, int64_t value) {
    if (idx < 0 || idx >= WITH_CODEGEN_LOOP_MAX) return;
    with_codegen_loop_result_vals[idx] = value;
}

int64_t with_codegen_loop_get_break(int32_t idx) {
    if (idx < 0 || idx >= WITH_CODEGEN_LOOP_MAX) return 0;
    return with_codegen_loop_break_bbs[idx];
}

int64_t with_codegen_loop_get_continue(int32_t idx) {
    if (idx < 0 || idx >= WITH_CODEGEN_LOOP_MAX) return 0;
    return with_codegen_loop_continue_bbs[idx];
}

int64_t with_codegen_loop_get_result(int32_t idx) {
    if (idx < 0 || idx >= WITH_CODEGEN_LOOP_MAX) return 0;
    return with_codegen_loop_result_vals[idx];
}

// ── I/O ────────────────────────────────────────────────────────────

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

// ── Assert ─────────────────────────────────────────────────────────

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

// ── C Builtins ─────────────────────────────────────────────────────
// Runtime implementations for __builtin_* functions translated by c_import.

int32_t with_clz(int32_t x)       { return x ? __builtin_clz((unsigned)x) : 32; }
int32_t with_ctz(int32_t x)       { return x ? __builtin_ctz((unsigned)x) : 32; }
int32_t with_popcount(int32_t x)   { return __builtin_popcount((unsigned)x); }
int32_t with_clzl(int64_t x)      { return x ? __builtin_clzll((unsigned long long)x) : 64; }
int32_t with_ctzl(int64_t x)      { return x ? __builtin_ctzll((unsigned long long)x) : 64; }
uint16_t with_bswap16(uint16_t x)  { return __builtin_bswap16(x); }
uint32_t with_bswap32(uint32_t x)  { return __builtin_bswap32(x); }
uint64_t with_bswap64(uint64_t x)  { return __builtin_bswap64(x); }

// ── System ─────────────────────────────────────────────────────────
// Implemented in runtime/helpers.c.
