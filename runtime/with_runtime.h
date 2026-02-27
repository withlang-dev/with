// With Language C Runtime — Header
// Used by the self-hosted compiler's C backend (CEmit.w).

#ifndef WITH_RUNTIME_H
#define WITH_RUNTIME_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// ── String type ────────────────────────────────────────────────────
// Same layout as in helpers.c.

typedef struct {
    const char *ptr;
    int64_t len;
} with_str;

#define WITH_STR_LIT(s) ((with_str){(s), (int64_t)(sizeof(s) - 1)})

with_str with_str_concat(with_str a, with_str b);
bool with_str_eq(with_str a, with_str b);
with_str with_str_from_cstr(const char *s);
with_str with_str_substr(with_str s, int64_t start, int64_t len);
with_str with_i32_to_str(int32_t n);
with_str with_i64_to_str(int64_t n);
with_str with_bool_to_str(bool b);

// ── Vec type ───────────────────────────────────────────────────────
// Generic dynamic array. Element type is erased; elem_size tracks layout.

typedef struct {
    void *ptr;
    int64_t len;
    int64_t cap;
    int64_t elem_size;
} with_vec;

with_vec with_vec_new(int64_t elem_size);
void with_vec_push(with_vec *v, const void *elem);
void *with_vec_get_ptr(with_vec *v, int64_t index);
int64_t with_vec_len(with_vec *v);

// Type-specific push/get helpers (avoid pointer-to-temp issues)
void with_vec_push_i32(with_vec *v, int32_t val);
int32_t with_vec_get_i32(with_vec *v, int64_t index);
void with_vec_push_i64(with_vec *v, int64_t val);
int64_t with_vec_get_i64(with_vec *v, int64_t index);
void with_vec_push_str(with_vec *v, with_str val);
with_str with_vec_get_str(with_vec *v, int64_t index);
void with_vec_push_bool(with_vec *v, bool val);
bool with_vec_get_bool(with_vec *v, int64_t index);

// ── Option types ───────────────────────────────────────────────────

typedef struct {
    bool has_value;
    int32_t value;
} with_option_i32;

typedef struct {
    bool has_value;
    int64_t value;
} with_option_i64;

typedef struct {
    bool has_value;
    with_str value;
} with_option_str;

// ── HashMap (from helpers.c — re-declared for convenience) ─────────

void *with_hashmap_new(int64_t key_size, int64_t val_size);
void with_hashmap_insert(void *handle, const void *key, const void *val, int64_t is_str_key);
int64_t with_hashmap_get(void *handle, const void *key, void *out_val, int64_t is_str_key);
int64_t with_hashmap_contains(void *handle, const void *key, int64_t is_str_key);
int64_t with_hashmap_remove(void *handle, const void *key, int64_t is_str_key);
int64_t with_hashmap_len(void *handle);
void with_hashmap_free(void *handle);

// ── I/O ────────────────────────────────────────────────────────────

void with_println_str(with_str s);
void with_println_i32(int32_t n);
void with_println_i64(int64_t n);
void with_println_bool(bool b);
void with_print_str(with_str s);

// ── Process ────────────────────────────────────────────────────────

int32_t with_arg_count(void);
with_str with_arg_at(int32_t idx);

// ── File I/O ───────────────────────────────────────────────────────

with_str with_fs_read_file(with_str path);
int32_t with_fs_write_file(with_str path, with_str data);

// ── Assert ─────────────────────────────────────────────────────────

void with_assert(bool cond, const char *msg, const char *file, int line);

// ── System ─────────────────────────────────────────────────────────

int32_t with_system(with_str cmd);

#endif // WITH_RUNTIME_H
