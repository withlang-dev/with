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
with_str with_str_concat_n(const with_str *parts, int64_t count);
with_str with_str_concat_n_move_first(const with_str *parts, int64_t count);
bool with_str_eq(with_str a, with_str b);
with_str with_str_from_cstr(const char *s);
with_str with_str_from_vec_u8(const void *bytes);
with_str with_str_substr(with_str s, int64_t start, int64_t len);
with_str with_str_slice(with_str s, int64_t start, int64_t end);
int64_t with_str_len(with_str s);
int32_t with_str_byte_at(with_str s, int64_t index);
int32_t with_str_starts_with(with_str s, with_str prefix);
int32_t with_str_ends_with(with_str s, with_str suffix);
int32_t with_str_contains(with_str haystack, with_str needle);
int64_t with_str_index_of(with_str haystack, with_str needle);
with_str with_str_replace(with_str s, with_str old, with_str new_s);
with_str with_i32_to_str(int32_t n);
with_str with_i64_to_str(int64_t n);
with_str with_bool_to_str(bool b);
int64_t with_parse_i64(with_str s);
with_str i64_to_string(int64_t n);
with_str with_str_from_byte(int32_t b);
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
with_str with_vec_str_join(with_vec *v, with_str sep);
void *with_slotmap_new(int64_t elem_size);
void with_slotmap_insert_out(void *map, const void *val, void *out_handle);
void *with_slotmap_get_ptr(void *map, uint32_t index, uint32_t generation);
int32_t with_slotmap_contains(void *map, uint32_t index, uint32_t generation);
int64_t with_slotmap_len(void *map);
int32_t with_slotmap_remove(void *map, uint32_t index, uint32_t generation, void *out_val);
int32_t with_slotmap_replace(void *map, uint32_t index, uint32_t generation, const void *val, void *out_old);
int32_t with_slotmap_set(void *map, uint32_t index, uint32_t generation, const void *val);
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
int64_t with_hashmap_remove(void *handle, const void *key, void *out_val, int64_t is_str_key);
int64_t with_hashmap_len(void *handle);
void with_hashmap_clear(void *handle);
void with_hashmap_keys_out(with_vec *out, void *handle, int64_t key_size);
void with_hashmap_free(void *handle);
void with_hashmap_increment(void *handle, const void *key, int64_t is_str_key);
void with_hashmap_decrement(void *handle, const void *key, int64_t is_str_key);

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
void with_eprintln(with_str s);
void with_eprint(with_str s);
void with_write(with_str s);
void with_ewrite(with_str s);
with_str with_read_line_stdin(void);
with_str with_read_bytes_stdin(int32_t count);
void with_write_stdout(with_str s);
void with_flush_stdout(void);

// ── Process ────────────────────────────────────────────────────────

int32_t with_arg_count(void);
with_str with_arg_at(int32_t idx);
void with_runtime_set_argv(int32_t argc, char **argv);
void with_install_interrupt_handlers(void);
void with_raise_stack_limit(void);
int32_t with_interrupt_requested(void);

// ── File I/O ───────────────────────────────────────────────────────

with_str with_fs_read_file(with_str path);
int32_t with_fs_file_exists(with_str path);
int32_t with_fs_write_file(with_str path, with_str data);
int32_t with_fs_mkdir_p(with_str path);
int32_t with_fs_mkdir(with_str path);
int32_t with_fs_is_dir(with_str path);
int32_t with_fs_remove_file(with_str path);
int32_t with_fs_chmod(with_str path, int32_t mode);
int32_t with_fs_rename_file(with_str old_path, with_str new_path);
int32_t with_fs_create_dir(with_str path);
int32_t with_fs_remove_dir(with_str path);
int32_t with_fs_remove_tree(with_str path);
int32_t with_fs_copy_tree(with_str src, with_str dst);
int32_t with_fs_symlink(with_str target, with_str link_path);
with_str with_fs_list_files(with_str path);
int64_t with_str_hash(with_str s);
void with_lines_out(with_vec *out, with_str s);
with_str with_getenv_str(with_str name);
int32_t with_setenv_str(with_str name, with_str value);
int32_t with_getpid(void);
int32_t with_process_alive(int32_t pid);
void with_fill_random(uint8_t *buf, int64_t len);

int32_t with_net_tcp_listen(int32_t port, int32_t backlog);
int32_t with_net_tcp_accept(int32_t listen_fd);
int32_t with_net_tcp_connect(with_str host, int32_t port);
int64_t with_net_send(int32_t fd, with_str data);
with_str with_net_recv(int32_t fd, int64_t max_len);
int32_t with_net_close(int32_t fd);
int32_t with_net_udp_bind(int32_t port);

// Extract a .tgz archive to dest directory. Returns 0 on success.

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
void with_runtime_run_one_step(void);
void with_runtime_core_init(void);
void with_runtime_core_shutdown(void);
int32_t with_runtime_core_has_fibers(void);
void with_runtime_core_run_one_step(void);
int32_t with_runtime_fiber_is_completed(int32_t fiber_id);
int32_t with_runtime_take_completed_fiber(int32_t fiber_id, const char **panic_msg_out, int32_t *panic_msg_len_out, int32_t *cancelled_return_out);
int32_t with_runtime_take_panicked_fiber(int32_t *fiber_id_out, const char **panic_msg_out, int32_t *panic_msg_len_out);
int32_t with_runtime_request_cancel(int32_t fiber_id);
int32_t with_runtime_current_cancel_requested(void);
void with_runtime_current_set_cancel_requested(void);
void with_runtime_current_set_cancelled_return(void);
int32_t with_runtime_completed_cancelled_return(int32_t fiber_id);

// ── Fiber / Task runtime ───────────────────────────────────────────

int32_t with_fiber_spawn(void (*entry_fn)(void *, void *), void *arg,
                          void *result_buf, int32_t result_size,
                          int32_t stack_size);
void with_fiber_yield(void);
void with_fiber_await(int32_t fiber_id);
void with_fiber_cleanup_await(int32_t fiber_id);
int32_t with_fiber_cancel(int32_t fiber_id);
void with_fiber_set_result(int64_t value);
int32_t with_fiber_in_fiber(void);
int32_t with_fiber_is_cancelled(void);
void with_fiber_select_mode(int32_t *fiber_ids, int32_t count, int32_t biased, int32_t *result_index);
void with_fiber_select(int32_t *fiber_ids, int32_t count, int32_t *result_index);
void with_fiber_set_cancelled_return(void);
int32_t with_fiber_was_cancelled_return(int32_t fiber_id);
void with_fiber_request_cancel_self(void);

// ── Async Scopes ───────────────────────────────────────────────────

int64_t with_scope_create(void);
void with_scope_track(int64_t handle, int32_t fiber_id);
void with_scope_await_all(int64_t handle);
void with_scope_destroy(int64_t handle);

// ── Channels (sized element slots) ─────────────────────────────────

int64_t with_channel_create(int32_t capacity, int32_t elem_size);
void with_channel_send(int64_t ch_handle, void *value_ptr);
int32_t with_channel_recv(int64_t ch_handle, void *out_ptr);
int32_t with_channel_try_recv(int64_t ch_handle, void *out_ptr);
void with_channel_close(int64_t ch_handle);
void with_channel_destroy(int64_t ch_handle);

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

int32_t with_exec_binary(with_str path);
int32_t with_exec_argv(with_str args);
int32_t with_exec_argv_cwd(with_str args, with_str cwd);
int32_t with_exec_argv_capture(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms);
int32_t with_exec_argv_capture_input(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms, with_str stdin_path);
int32_t with_exec_argv_capture_cwd(with_str args, with_str stdout_path, with_str stderr_path, int32_t timeout_ms, with_str cwd);
int32_t with_exec_argv_capture_spawn(with_str args, with_str stdout_path, with_str stderr_path);
int32_t with_exec_wait(int32_t pid, int32_t timeout_ms);
int64_t with_thread_spawn(void *fn_ptr, void *ctx);
int32_t with_thread_join(int64_t handle);

#endif // WITH_RUNTIME_H
