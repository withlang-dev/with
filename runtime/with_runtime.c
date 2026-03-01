// With Language C Runtime — Implementation
// Provides Vec, string ops, I/O, and assert for the C backend.

#include "with_runtime.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

// ── Vec operations ─────────────────────────────────────────────────

with_vec with_vec_new(int64_t elem_size) {
    with_vec v;
    v.ptr = NULL;
    v.len = 0;
    v.cap = 0;
    v.elem_size = elem_size;
    return v;
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

// ── Assert ─────────────────────────────────────────────────────────

void with_assert(bool cond, const char *msg, const char *file, int line) {
    if (!cond) {
        fprintf(stderr, "assertion failed: %s at %s:%d\n", msg, file, line);
        abort();
    }
}

// ── System ─────────────────────────────────────────────────────────
// Implemented in runtime/helpers.c.
