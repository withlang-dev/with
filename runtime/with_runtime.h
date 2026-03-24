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
#define with_len(v) ((v).len)
#define with_is_empty(v) (((v).len == 0) ? 1 : 0)

with_str with_str_concat(with_str a, with_str b);
bool with_str_eq(with_str a, with_str b);
with_str with_str_from_cstr(const char *s);
with_str with_str_substr(with_str s, int64_t start, int64_t len);
with_str with_str_slice(with_str s, int64_t start, int64_t end);
int64_t with_str_len(with_str s);
int32_t with_str_byte_at(with_str s, int64_t index);
int32_t with_str_starts_with(with_str s, with_str prefix);
int32_t with_str_ends_with(with_str s, with_str suffix);
int32_t with_str_contains(with_str haystack, with_str needle);
int64_t with_str_index_of(with_str haystack, with_str needle);
with_str with_i32_to_str(int32_t n);
with_str with_i64_to_str(int64_t n);
with_str with_bool_to_str(bool b);
int64_t with_parse_i64(with_str s);
with_str int_to_string(int32_t n);
with_str i64_to_string(int64_t n);
with_str str_from_byte(int32_t b);

// ── Vec type ───────────────────────────────────────────────────────
// Generic dynamic array. Element type is erased; elem_size tracks layout.

typedef struct {
    void *ptr;
    int64_t len;
    int64_t cap;
    int64_t elem_size;
} with_vec;

with_vec with_vec_new(int64_t elem_size);
void with_vec_new_out(with_vec *out, int64_t elem_size);
void with_vec_push(with_vec *v, const void *elem);
void *with_vec_get_ptr(with_vec *v, int64_t index);
int64_t with_vec_len(with_vec *v);
void with_vec_clear(with_vec *v);

// Type-specific push/get helpers (avoid pointer-to-temp issues)
void with_vec_push_i32(with_vec *v, int32_t val);
int32_t with_vec_get_i32(with_vec *v, int64_t index);
void with_vec_push_i64(with_vec *v, int64_t val);
int64_t with_vec_get_i64(with_vec *v, int64_t index);
void with_vec_push_str(with_vec *v, with_str val);
with_str with_vec_get_str(with_vec *v, int64_t index);
void with_vec_push_bool(with_vec *v, bool val);
bool with_vec_get_bool(with_vec *v, int64_t index);
void with_vec_set_i32(with_vec *v, int64_t index, int32_t val);
void with_vec_set_i64(with_vec *v, int64_t index, int64_t val);
void with_vec_remove(with_vec *v, int64_t index);
void with_codegen_loop_set_break(int32_t idx, int64_t bb);
void with_codegen_loop_set_continue(int32_t idx, int64_t bb);
void with_codegen_loop_set_result(int32_t idx, int64_t value);
int64_t with_codegen_loop_get_break(int32_t idx);
int64_t with_codegen_loop_get_continue(int32_t idx);
int64_t with_codegen_loop_get_result(int32_t idx);

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

with_option_i32 with_vec_pop_i32(with_vec *v);

// ── HashMap (from helpers.c — re-declared for convenience) ─────────

void *with_hashmap_new(int64_t key_size, int64_t val_size);
void with_hashmap_new_out(void **out, int64_t key_size, int64_t val_size);
void with_hashmap_new_at(void *base, int64_t offset, int64_t key_size, int64_t val_size);
void with_hashmap_insert(void *handle, const void *key, const void *val, int64_t is_str_key);
int64_t with_hashmap_get(void *handle, const void *key, void *out_val, int64_t is_str_key);
int64_t with_hashmap_contains(void *handle, const void *key, int64_t is_str_key);
int64_t with_hashmap_remove(void *handle, const void *key, int64_t is_str_key);
int64_t with_hashmap_len(void *handle);
void with_hashmap_clear(void *handle);
void with_hashmap_free(void *handle);

// ── F-string formatting ─────────────────────────────────────────────

with_str with_fmt_i32(int32_t n);
with_str with_fmt_i64(int64_t n);
with_str with_fmt_u32(uint32_t n);
with_str with_fmt_u64(uint64_t n);
with_str with_fmt_int_spec(int64_t val, int32_t is_unsigned,
                           int64_t flags, int32_t width,
                           int32_t precision, int32_t mode);
with_str with_fmt_f64(double n);
with_str with_fmt_f64_spec(double val, int64_t flags, int32_t width,
                           int32_t precision, int32_t mode);
with_str with_fmt_str(with_str s);
with_str with_fmt_str_spec(with_str val, int64_t flags, int32_t width,
                           int32_t precision);
with_str with_fmt_bool(int32_t b);
with_str with_fmt_str_debug(with_str s);

// ── I/O ────────────────────────────────────────────────────────────

void with_println_str(with_str s);
void with_println_i32(int32_t n);
void with_println_i64(int64_t n);
void with_println_bool(bool b);
void with_print_str(with_str s);
void print(with_str s);
void eprintln(with_str s);
void with_eprintln(with_str s);

// ── Process ────────────────────────────────────────────────────────

int32_t with_arg_count(void);
with_str with_arg_at(int32_t idx);
void with_runtime_set_argv(int32_t argc, char **argv);
void with_install_interrupt_handlers(void);
void with_raise_stack_limit(void);
int32_t with_interrupt_requested(void);

// ── File I/O ───────────────────────────────────────────────────────

with_str with_fs_read_file(with_str path);
int32_t with_fs_write_file(with_str path, with_str data);
int32_t with_fs_mkdir_p(with_str path);
int64_t with_str_hash(with_str s);
void with_lines_out(with_vec *out, with_str s);
with_str with_getenv_str(with_str name);
int32_t with_setenv_str(with_str name, with_str value);

// ── HTTP (libcurl) ──────────────────────────────────────────────

// GET a URL, return response body as str. Returns empty on error.
with_str with_http_get(with_str url);

// Download a URL to a file path. Returns 0 on success, -1 on error.
int32_t with_http_download(with_str url, with_str path);

// Extract a .tgz archive to dest directory. Returns 0 on success.
int32_t with_extract_tgz(with_str archive, with_str dest);

// String builder helpers (used by compiler debug dumps).
int64_t with_sb_new(void);
void with_sb_append(int64_t handle, with_str s);
with_str with_sb_build(int64_t handle);

// ── Assert ─────────────────────────────────────────────────────────

void with_assert(bool cond, const char *msg, const char *file, int line);
void with_panic(with_str msg, with_str file, int32_t line);

// ── Runtime lifecycle ──────────────────────────────────────────────

void with_runtime_init(void);
void with_runtime_shutdown(void);
void with_runtime_run(void);
int32_t with_runtime_has_fibers(void);

// ── Fiber / Task runtime ───────────────────────────────────────────

int32_t with_fiber_spawn(void (*entry_fn)(void *), void *arg);
void with_fiber_yield(void);
int64_t with_fiber_await(int32_t fiber_id);
int32_t with_fiber_cancel(int32_t fiber_id);
void with_fiber_set_result(int64_t value);
int32_t with_fiber_in_fiber(void);
int32_t with_fiber_select(int32_t *fiber_ids, int32_t count, int64_t *result_out);

// ── Channels ───────────────────────────────────────────────────────

void *with_channel_create(int32_t capacity);
void with_channel_send(void *ch_ptr, int64_t value);
int64_t with_channel_recv(void *ch_ptr);
int32_t with_channel_try_recv(void *ch_ptr, int64_t *out);
void with_channel_close(void *ch_ptr);
void with_channel_destroy(void *ch_ptr);

// ── C Builtins ─────────────────────────────────────────────────────

int32_t with_clz(int32_t x);
int32_t with_ctz(int32_t x);
int32_t with_popcount(int32_t x);
int32_t with_clzl(int64_t x);
int32_t with_ctzl(int64_t x);
uint16_t with_bswap16(uint16_t x);
uint32_t with_bswap32(uint32_t x);
uint64_t with_bswap64(uint64_t x);

// ── System ─────────────────────────────────────────────────────────

int32_t with_system(with_str cmd);

#endif // WITH_RUNTIME_H
