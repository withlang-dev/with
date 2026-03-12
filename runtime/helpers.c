// With Language Runtime Helpers
// Small C wrapper functions for stdlib features that need special handling.

#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 200809L
#endif

#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <signal.h>
#include <stdbool.h>
#include <sys/resource.h>
#ifdef __APPLE__
#include <crt_externs.h>
#endif

// Common string type used across runtime helpers
typedef struct {
    const char *ptr;
    int64_t len;
} with_str;

typedef struct {
    void *ptr;
    int64_t len;
    int64_t cap;
    int64_t elem_size;
} with_vec;

typedef struct {
    bool has_value;
    int32_t value;
} with_option_i32;

typedef struct {
    char *buf;
    int64_t len;
    int64_t cap;
} with_str_builder;

#ifndef WITH_EMBEDDED_STDLIB_HEADER
#define WITH_EMBEDDED_STDLIB_HEADER "../out/lib/embedded_stdlib.inc.h"
#endif
#if defined(__has_include)
#if __has_include(WITH_EMBEDDED_STDLIB_HEADER)
#include WITH_EMBEDDED_STDLIB_HEADER
#else
with_str with_embedded_std_source(with_str path) {
    (void)path;
    with_str out = { "", 0 };
    return out;
}
#endif
#else
#include WITH_EMBEDDED_STDLIB_HEADER
#endif

static int32_t with_saved_argc = 0;
static char **with_saved_argv = NULL;
static volatile sig_atomic_t with_interrupt_flag = 0;
static volatile sig_atomic_t with_interrupt_count = 0;
static int64_t with_hashmap_trace_count = 0;

static int with_trace_hashmap_enabled(void) {
    static int cached = -1;
    if (cached >= 0) return cached;
    const char *raw = getenv("WITH_TRACE_HASHMAP");
    cached = (raw && raw[0] != '\0' && !(raw[0] == '0' && raw[1] == '\0')) ? 1 : 0;
    return cached;
}

static void with_interrupt_signal_handler(int signo) {
    (void)signo;
    with_interrupt_flag = 1;
    with_interrupt_count = with_interrupt_count + 1;
    if (with_interrupt_count >= 2) {
        _exit(130);
    }
}

void with_runtime_set_argv(int32_t argc, char **argv) {
    with_saved_argc = argc;
    with_saved_argv = argv;
}

void with_install_interrupt_handlers(void) {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = with_interrupt_signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    (void)sigaction(SIGINT, &sa, NULL);
    (void)sigaction(SIGTERM, &sa, NULL);
}

void with_raise_stack_limit(void) {
#ifdef RLIMIT_STACK
    struct rlimit lim;
    if (getrlimit(RLIMIT_STACK, &lim) != 0) {
        return;
    }

    rlim_t want = (rlim_t)(64ull * 1024ull * 1024ull);
    if (lim.rlim_max != RLIM_INFINITY && want > lim.rlim_max) {
        want = lim.rlim_max;
    }
    if (want > lim.rlim_cur) {
        lim.rlim_cur = want;
        (void)setrlimit(RLIMIT_STACK, &lim);
    }
#endif
}

int32_t with_interrupt_requested(void) {
    return with_interrupt_flag ? 1 : 0;
}

static void with_sb_reserve(with_str_builder *sb, int64_t need) {
    if (need <= sb->cap) return;
    int64_t cap = sb->cap > 0 ? sb->cap : 256;
    while (cap < need) {
        cap *= 2;
    }
    char *next = (char *)realloc(sb->buf, (size_t)cap);
    if (!next) return;
    sb->buf = next;
    sb->cap = cap;
}

int64_t with_sb_new(void) {
    with_str_builder *sb = (with_str_builder *)calloc(1, sizeof(with_str_builder));
    if (!sb) return 0;
    return (int64_t)(intptr_t)sb;
}

void with_sb_append(int64_t handle, with_str s) {
    with_str_builder *sb = (with_str_builder *)(intptr_t)handle;
    if (!sb || s.len <= 0) return;
    int64_t need = sb->len + s.len + 1;
    with_sb_reserve(sb, need);
    if (!sb->buf) return;
    memcpy(sb->buf + sb->len, s.ptr, (size_t)s.len);
    sb->len += s.len;
    sb->buf[sb->len] = '\0';
}

with_str with_sb_build(int64_t handle) {
    with_str_builder *sb = (with_str_builder *)(intptr_t)handle;
    if (!sb || !sb->buf) {
        with_str out = { "", 0 };
        return out;
    }
    with_str out = { sb->buf, sb->len };
    return out;
}

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

void with_vec_new_out(with_vec *out, int64_t elem_size) {
    if (!out) return;
    out->ptr = NULL;
    out->len = 0;
    out->cap = 0;
    out->elem_size = elem_size;
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
    if (!v || !elem) return;
    if (v->len >= v->cap) {
        with_vec_grow(v);
    }
    memcpy((char *)v->ptr + v->len * v->elem_size, elem, (size_t)v->elem_size);
    v->len++;
}

void *with_vec_get_ptr(with_vec *v, int64_t index) {
    if (!v) return NULL;
    return (char *)v->ptr + index * v->elem_size;
}

int64_t with_vec_len(with_vec *v) {
    if (!v) return 0;
    return v->len;
}

void with_vec_clear(with_vec *v) {
    if (!v) return;
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

void with_vec_push_bool(with_vec *v, bool val) {
    with_vec_push(v, &val);
}

bool with_vec_get_bool(with_vec *v, int64_t index) {
    return *(bool *)with_vec_get_ptr(v, index);
}

void with_vec_set_i32(with_vec *v, int64_t index, int32_t val) {
    if (!v) return;
    if (index >= 0 && index < v->len) {
        ((int32_t *)v->ptr)[index] = val;
    }
}

void with_vec_remove(with_vec *v, int64_t index) {
    if (!v) return;
    if (index < 0 || index >= v->len) return;
    char *base = (char *)v->ptr;
    int64_t es = v->elem_size;
    memmove(base + index * es, base + (index + 1) * es, (size_t)((v->len - index - 1) * es));
    v->len--;
}

with_option_i32 with_vec_pop_i32(with_vec *v) {
    with_option_i32 r;
    if (!v || v->len <= 0) {
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

// Convert i32 to owned string.
with_str with_i32_to_str(int32_t n) {
    char tmp[32];
    int wrote = snprintf(tmp, sizeof(tmp), "%d", n);
    if (wrote <= 0) {
        with_str out = { "", 0 };
        return out;
    }
    char *buf = (char *)malloc((size_t)wrote + 1);
    if (!buf) {
        with_str out = { "", 0 };
        return out;
    }
    memcpy(buf, tmp, (size_t)wrote + 1);
    with_str out = { buf, (int64_t)wrote };
    return out;
}

// Legacy alias used by self-hosted sources.
with_str i32_to_str(int32_t n) {
    return with_i32_to_str(n);
}

// Alias used by self-hosted compiler (extern fn int_to_string).
with_str int_to_string(int32_t n) {
    return with_i32_to_str(n);
}

// Alias used by self-hosted compiler (extern fn i64_to_string).
with_str i64_to_string(int64_t n) {
    char tmp[32];
    int wrote = snprintf(tmp, sizeof(tmp), "%lld", (long long)n);
    if (wrote <= 0) {
        with_str out = { "", 0 };
        return out;
    }
    char *buf = (char *)malloc((size_t)wrote + 1);
    if (!buf) {
        with_str out = { "", 0 };
        return out;
    }
    memcpy(buf, tmp, (size_t)wrote + 1);
    with_str out = { buf, (int64_t)wrote };
    return out;
}

// Print a string to stderr with trailing newline.
void with_eprintln(with_str s) {
    if (s.ptr && s.len > 0) {
        fwrite(s.ptr, 1, (size_t)s.len, stderr);
    }
    fputc('\n', stderr);
}

// Aliases used by self-hosted compiler externs.
void eprintln(with_str s) {
    with_eprintln(s);
}

void print(with_str s) {
    if (s.ptr && s.len > 0) {
        fwrite(s.ptr, 1, (size_t)s.len, stdout);
    }
}

// Convert a single byte value to a one-char string.
with_str str_from_byte(int32_t b) {
    char *buf = (char *)malloc(2);
    if (!buf) {
        with_str out = { "", 0 };
        return out;
    }
    buf[0] = (char)(b & 0xFF);
    buf[1] = '\0';
    with_str out = { buf, 1 };
    return out;
}

// time(NULL) wrapper — Zig/LLVM has trouble with NULL pointer args
int64_t with_time_now(void) {
    return (int64_t)time(NULL);
}

// ---- Process helpers ----

// Command-line argument count.
int32_t with_arg_count(void) {
    if (with_saved_argv) {
        return with_saved_argc;
    }
#ifdef __APPLE__
    int *argc_ptr = _NSGetArgc();
    return argc_ptr ? (int32_t)(*argc_ptr) : 0;
#else
    return 0;
#endif
}

// Command-line argument at index. Returns "" when out of range.
with_str with_arg_at(int32_t idx) {
    if (with_saved_argv) {
        if (idx < 0 || idx >= with_saved_argc) {
            with_str out = { "", 0 };
            return out;
        }
        const char *s = with_saved_argv[idx];
        if (!s) {
            with_str out = { "", 0 };
            return out;
        }
        with_str out = { s, (int64_t)strlen(s) };
        return out;
    }
#ifdef __APPLE__
    int *argc_ptr = _NSGetArgc();
    char ***argv_ptr = _NSGetArgv();
    if (!argc_ptr || !argv_ptr || idx < 0 || idx >= *argc_ptr) {
        with_str out = { "", 0 };
        return out;
    }
    const char *s = (*argv_ptr)[idx];
    if (!s) {
        with_str out = { "", 0 };
        return out;
    }
    with_str out = { s, (int64_t)strlen(s) };
    return out;
#else
    (void)idx;
    with_str out = { "", 0 };
    return out;
#endif
}

// getenv wrapper returning with_str.
with_str with_getenv_str(with_str name) {
    char *name_buf = (char *)malloc((size_t)name.len + 1);
    memcpy(name_buf, name.ptr, (size_t)name.len);
    name_buf[name.len] = '\0';
    const char *val = getenv(name_buf);
    free(name_buf);
    if (!val) {
        with_str out = { "", 0 };
        return out;
    }
    with_str out = { val, (int64_t)strlen(val) };
    return out;
}

// setenv wrapper from with_str names/values.
int32_t with_setenv_str(with_str name, with_str value) {
    char *name_buf = (char *)malloc((size_t)name.len + 1);
    char *value_buf = (char *)malloc((size_t)value.len + 1);
    memcpy(name_buf, name.ptr, (size_t)name.len);
    memcpy(value_buf, value.ptr, (size_t)value.len);
    name_buf[name.len] = '\0';
    value_buf[value.len] = '\0';
    int rc = setenv(name_buf, value_buf, 1);
    free(name_buf);
    free(value_buf);
    return (int32_t)rc;
}

// system() wrapper for with_str command input.
int32_t with_system(with_str cmd) {
    char *buf = (char *)malloc((size_t)cmd.len + 1);
    if (!buf) return -1;
    memcpy(buf, cmd.ptr, (size_t)cmd.len);
    buf[cmd.len] = '\0';
    int rc = system(buf);
    free(buf);
    return (int32_t)rc;
}

// getenv wrapper that returns "" instead of NULL for missing vars
const char *with_getenv(const char *name) {
    const char *val = getenv(name);
    return val ? val : "";
}

int64_t with_parse_i64(with_str s) {
    if (!s.ptr || s.len <= 0) {
        return 0;
    }

    char *buf = (char *)malloc((size_t)s.len + 1);
    if (!buf) {
        return 0;
    }

    memcpy(buf, s.ptr, (size_t)s.len);
    buf[s.len] = '\0';
    long long v = atoll(buf);
    free(buf);
    return (int64_t)v;
}

// String split: splits src (ptr+len) by delim (ptr+len).
// Returns number of parts found. Writes ptr+len pairs into out_parts buffer.
// out_parts layout: [ptr0, len0, ptr1, len1, ...]
// max_parts: maximum number of parts to write.
int64_t with_str_split(const char *src, int64_t src_len,
                        const char *delim, int64_t delim_len,
                        void **out_parts, int64_t *out_lens,
                        int64_t max_parts) {
    if (src_len == 0 || delim_len == 0 || max_parts == 0) {
        if (max_parts > 0) {
            out_parts[0] = (void *)src;
            out_lens[0] = src_len;
            return 1;
        }
        return 0;
    }
    int64_t count = 0;
    int64_t start = 0;
    for (int64_t i = 0; i <= src_len - delim_len; i++) {
        if (memcmp(src + i, delim, delim_len) == 0) {
            if (count < max_parts) {
                out_parts[count] = (void *)(src + start);
                out_lens[count] = i - start;
                count++;
            }
            start = i + delim_len;
            i = start - 1; // will be incremented by loop
        }
    }
    // Last segment
    if (count < max_parts) {
        out_parts[count] = (void *)(src + start);
        out_lens[count] = src_len - start;
        count++;
    }
    return count;
}

void with_lines_out(with_vec *out, with_str s) {
    if (!out) return;
    with_vec_new_out(out, (int64_t)sizeof(with_str));
    if (s.len < 0) {
        return;
    }

    int64_t max_parts = s.len + 1;
    if (max_parts < 1) {
        max_parts = 1;
    }

    void **parts = (void **)malloc((size_t)max_parts * sizeof(void *));
    int64_t *lens = (int64_t *)malloc((size_t)max_parts * sizeof(int64_t));
    if (!parts || !lens) {
        free(parts);
        free(lens);
        return;
    }

    int64_t count = with_str_split(s.ptr, s.len, "\n", 1, parts, lens, max_parts);
    for (int64_t i = 0; i < count; i++) {
        with_str seg = { (const char *)parts[i], lens[i] };
        with_vec_push_str(out, seg);
    }

    free(parts);
    free(lens);
}

with_vec with_lines(with_str s) {
    with_vec out;
    with_lines_out(&out, s);
    return out;
}

// String join: joins count strings (ptrs+lens) with separator.
// Returns a newly malloc'd string. Sets *out_len to result length.
char *with_str_join(void **ptrs, int64_t *lens, int64_t count,
                    const char *sep, int64_t sep_len,
                    int64_t *out_len) {
    // Calculate total length
    int64_t total = 0;
    for (int64_t i = 0; i < count; i++) {
        total += lens[i];
        if (i > 0) total += sep_len;
    }
    char *buf = (char *)malloc(total + 1);
    int64_t pos = 0;
    for (int64_t i = 0; i < count; i++) {
        if (i > 0 && sep_len > 0) {
            memcpy(buf + pos, sep, sep_len);
            pos += sep_len;
        }
        memcpy(buf + pos, ptrs[i], lens[i]);
        pos += lens[i];
    }
    buf[total] = '\0';
    *out_len = total;
    return buf;
}

// ---- String helpers ----

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

double with_parse_float(with_str s) {
    // Null-terminate for strtod (with_str is not null-terminated)
    char buf[64];
    size_t n = (size_t)s.len;
    if (n >= sizeof(buf)) n = sizeof(buf) - 1;
    memcpy(buf, s.ptr, n);
    buf[n] = '\0';
    return strtod(buf, NULL);
}

bool with_str_eq(with_str a, with_str b) {
    if (a.len != b.len) {
        return false;
    }
    if (a.len == 0) {
        return true;
    }
    return memcmp(a.ptr, b.ptr, (size_t)a.len) == 0;
}

int64_t with_str_len(with_str s) {
    return s.len;
}

// Check if string ends with suffix
int32_t with_str_ends_with(with_str s, with_str suffix) {
    if (suffix.len > s.len) return 0;
    return memcmp(s.ptr + s.len - suffix.len, suffix.ptr, (size_t)suffix.len) == 0;
}

// Check if string starts with prefix
int32_t with_str_starts_with(with_str s, with_str prefix) {
    if (prefix.len > s.len) return 0;
    return memcmp(s.ptr, prefix.ptr, (size_t)prefix.len) == 0;
}

// Check if string contains substring
int32_t with_str_contains(with_str haystack, with_str needle) {
    if (needle.len == 0) return 1;
    if (needle.len > haystack.len) return 0;
    for (int64_t i = 0; i <= haystack.len - needle.len; i++) {
        if (memcmp(haystack.ptr + i, needle.ptr, (size_t)needle.len) == 0)
            return 1;
    }
    return 0;
}

// Find first index of needle in haystack. Returns -1 if not found.
int64_t with_str_index_of(with_str haystack, with_str needle) {
    if (needle.len == 0) return 0;
    if (needle.len > haystack.len) return -1;
    for (int64_t i = 0; i <= haystack.len - needle.len; i++) {
        if (memcmp(haystack.ptr + i, needle.ptr, (size_t)needle.len) == 0)
            return i;
    }
    return -1;
}

// Trim whitespace from both ends. Returns a view (no allocation).
with_str with_str_trim(with_str s) {
    int64_t start = 0;
    while (start < s.len && (s.ptr[start] == ' ' || s.ptr[start] == '\t' ||
           s.ptr[start] == '\n' || s.ptr[start] == '\r'))
        start++;
    int64_t end = s.len;
    while (end > start && (s.ptr[end-1] == ' ' || s.ptr[end-1] == '\t' ||
           s.ptr[end-1] == '\n' || s.ptr[end-1] == '\r'))
        end--;
    with_str out;
    out.ptr = s.ptr + start;
    out.len = end - start;
    return out;
}

// Substring extraction. Returns a view (no allocation).
with_str with_str_substr(with_str s, int64_t start, int64_t len) {
    with_str out;
    if (start < 0) start = 0;
    if (start > s.len) start = s.len;
    if (len < 0 || start + len > s.len) len = s.len - start;
    out.ptr = s.ptr + start;
    out.len = len;
    return out;
}

with_str with_str_slice(with_str s, int64_t start, int64_t end) {
    if (end < start) end = start;
    return with_str_substr(s, start, end - start);
}

int32_t with_str_byte_at(with_str s, int64_t index) {
    if (index < 0 || index >= s.len) return 0;
    return (int32_t)(unsigned char)s.ptr[index];
}

// Convert string to uppercase. Returns newly allocated string.
with_str with_str_to_upper(with_str s) {
    char *buf = (char *)malloc((size_t)s.len + 1);
    for (int64_t i = 0; i < s.len; i++) {
        char c = s.ptr[i];
        buf[i] = (c >= 'a' && c <= 'z') ? (c - 32) : c;
    }
    buf[s.len] = '\0';
    with_str out = { buf, s.len };
    return out;
}

// Convert string to lowercase. Returns newly allocated string.
with_str with_str_to_lower(with_str s) {
    char *buf = (char *)malloc((size_t)s.len + 1);
    for (int64_t i = 0; i < s.len; i++) {
        char c = s.ptr[i];
        buf[i] = (c >= 'A' && c <= 'Z') ? (c + 32) : c;
    }
    buf[s.len] = '\0';
    with_str out = { buf, s.len };
    return out;
}

// Repeat a string n times. Returns newly allocated string.
with_str with_str_repeat(with_str s, int64_t n) {
    if (n <= 0) {
        with_str out = { "", 0 };
        return out;
    }
    int64_t total = s.len * n;
    char *buf = (char *)malloc((size_t)total + 1);
    for (int64_t i = 0; i < n; i++) {
        memcpy(buf + i * s.len, s.ptr, (size_t)s.len);
    }
    buf[total] = '\0';
    with_str out = { buf, total };
    return out;
}

// Replace all occurrences of old with new. Returns newly allocated string.
with_str with_str_replace(with_str s, with_str old_s, with_str new_s) {
    if (old_s.len == 0) {
        // No replacement possible
        char *buf = (char *)malloc((size_t)s.len + 1);
        memcpy(buf, s.ptr, (size_t)s.len);
        buf[s.len] = '\0';
        with_str out = { buf, s.len };
        return out;
    }
    // Count occurrences
    int64_t count = 0;
    for (int64_t i = 0; i <= s.len - old_s.len; i++) {
        if (memcmp(s.ptr + i, old_s.ptr, (size_t)old_s.len) == 0) {
            count++;
            i += old_s.len - 1;
        }
    }
    int64_t total = s.len + count * (new_s.len - old_s.len);
    char *buf = (char *)malloc((size_t)total + 1);
    int64_t pos = 0;
    int64_t src = 0;
    while (src <= s.len - old_s.len) {
        if (memcmp(s.ptr + src, old_s.ptr, (size_t)old_s.len) == 0) {
            memcpy(buf + pos, new_s.ptr, (size_t)new_s.len);
            pos += new_s.len;
            src += old_s.len;
        } else {
            buf[pos++] = s.ptr[src++];
        }
    }
    // Copy remaining
    while (src < s.len) {
        buf[pos++] = s.ptr[src++];
    }
    buf[total] = '\0';
    with_str out = { buf, total };
    return out;
}

// ---- Vec.join ----

with_str with_vec_str_join(with_vec *v, with_str sep) {
    if (!v || v->len == 0) {
        with_str out = { "", 0 };
        return out;
    }
    // Calculate total length
    int64_t total = 0;
    for (int64_t i = 0; i < v->len; i++) {
        with_str s = *(with_str *)((char *)v->ptr + i * v->elem_size);
        total += s.len;
        if (i > 0) total += sep.len;
    }
    char *buf = (char *)malloc(total + 1);
    int64_t pos = 0;
    for (int64_t i = 0; i < v->len; i++) {
        if (i > 0) {
            memcpy(buf + pos, sep.ptr, sep.len);
            pos += sep.len;
        }
        with_str s = *(with_str *)((char *)v->ptr + i * v->elem_size);
        memcpy(buf + pos, s.ptr, s.len);
        pos += s.len;
    }
    buf[total] = '\0';
    with_str out = { buf, total };
    return out;
}

// ---- str.split (Vec[str] version) ----

void with_str_split_vec(with_vec *out, with_str s, with_str delim) {
    with_vec_new_out(out, (int64_t)sizeof(with_str));
    if (s.len <= 0 && delim.len > 0) {
        with_str empty = { "", 0 };
        with_vec_push(out, &empty);
        return;
    }

    int64_t max_parts = s.len + 1;
    if (max_parts < 1) max_parts = 1;
    void **parts = (void **)malloc((size_t)max_parts * sizeof(void *));
    int64_t *lens = (int64_t *)malloc((size_t)max_parts * sizeof(int64_t));
    if (!parts || !lens) { free(parts); free(lens); return; }

    int64_t count = with_str_split(s.ptr, s.len, delim.ptr, delim.len, parts, lens, max_parts);
    for (int64_t i = 0; i < count; i++) {
        with_str part = { (const char *)parts[i], lens[i] };
        with_vec_push(out, &part);
    }
    free(parts);
    free(lens);
}

// ---- HashMap ----

typedef struct {
    char *keys;       // flat array: cap entries, each key_size bytes
    char *values;     // flat array: cap entries, each val_size bytes
    uint8_t *states;  // 0=empty, 1=occupied, 2=tombstone
    int64_t cap;
    int64_t len;
    int64_t key_size;
    int64_t val_size;
} WithHashMap;

// FNV-1a hash
static uint64_t hash_bytes(const void *data, int64_t size) {
    uint64_t h = 14695981039346656037ULL;
    const uint8_t *p = (const uint8_t *)data;
    for (int64_t i = 0; i < size; i++) {
        h ^= p[i];
        h *= 1099511628211ULL;
    }
    return h;
}

// Hash a key. For str keys (is_str_key=1), hash the pointed-to string content.
static uint64_t hash_key(const void *key, int64_t key_size, int64_t is_str_key) {
    if (is_str_key) {
        // str = { const char *ptr, int64_t len }
        const char *str_ptr = *(const char **)key;
        int64_t str_len = *(const int64_t *)((const char *)key + sizeof(char *));
        return hash_bytes(str_ptr, str_len);
    }
    return hash_bytes(key, key_size);
}

// Compare two keys for equality.
static int keys_equal(const void *a, const void *b, int64_t key_size, int64_t is_str_key) {
    if (is_str_key) {
        const char *a_ptr = *(const char **)a;
        int64_t a_len = *(const int64_t *)((const char *)a + sizeof(char *));
        const char *b_ptr = *(const char **)b;
        int64_t b_len = *(const int64_t *)((const char *)b + sizeof(char *));
        if (a_len != b_len) return 0;
        return memcmp(a_ptr, b_ptr, a_len) == 0;
    }
    return memcmp(a, b, key_size) == 0;
}

static void hashmap_grow(WithHashMap *m, int64_t is_str_key);

static int hashmap_invalid(WithHashMap *m) {
    if (!m) return 1;
    if (m->cap <= 0 || m->cap > (1LL << 30)) return 1;
    if (m->key_size <= 0 || m->key_size > (1LL << 20)) return 1;
    if (m->val_size <= 0 || m->val_size > (1LL << 20)) return 1;
    if (!m->keys || !m->values || !m->states) return 1;
    return 0;
}

void *with_hashmap_new(int64_t key_size, int64_t val_size) {
    WithHashMap *m = (WithHashMap *)calloc(1, sizeof(WithHashMap));
    m->cap = 16;
    m->key_size = key_size;
    m->val_size = val_size;
    m->keys = (char *)calloc(16, key_size);
    m->values = (char *)calloc(16, val_size);
    m->states = (uint8_t *)calloc(16, 1);
    if (with_trace_hashmap_enabled()) {
        fprintf(stderr, "[trace-hashmap] new handle=%p key_size=%lld val_size=%lld cap=%lld\n",
                (void *)m, (long long)key_size, (long long)val_size, (long long)m->cap);
    }
    return m;
}

void with_hashmap_new_out(void **out, int64_t key_size, int64_t val_size) {
    if (!out) return;
    *out = with_hashmap_new(key_size, val_size);
}

void with_hashmap_new_at(void *base, int64_t offset, int64_t key_size, int64_t val_size) {
    if (!base) return;
    void **slot = (void **)((char *)base + offset);
    *slot = with_hashmap_new(key_size, val_size);
}

void with_hashmap_insert(void *handle, const void *key, const void *val, int64_t is_str_key) {
    WithHashMap *m = (WithHashMap *)handle;
    if (hashmap_invalid(m)) {
        void *ra = __builtin_return_address(0);
        fprintf(stderr, "with_hashmap_insert: invalid handle=%p ra=%p\n", handle, ra);
        return;
    }
    if (m->len * 10 >= m->cap * 7) {
        hashmap_grow(m, is_str_key);
    }
    uint64_t h = hash_key(key, m->key_size, is_str_key);
    int64_t idx = (int64_t)(h % (uint64_t)m->cap);
    int64_t first_tombstone = -1;
    for (int64_t probe = 0; probe < m->cap; probe++) {
        int64_t i = (idx + probe) % m->cap;
        if (m->states[i] == 0) {
            int64_t target = (first_tombstone >= 0) ? first_tombstone : i;
            memcpy(m->keys + target * m->key_size, key, m->key_size);
            memcpy(m->values + target * m->val_size, val, m->val_size);
            m->states[target] = 1;
            m->len++;
            return;
        } else if (m->states[i] == 2) {
            if (first_tombstone < 0) first_tombstone = i;
        } else if (m->states[i] == 1) {
            if (keys_equal(m->keys + i * m->key_size, key, m->key_size, is_str_key)) {
                memcpy(m->values + i * m->val_size, val, m->val_size);
                return;
            }
        }
    }
}

// Returns 1 if found (writes value to out_val), 0 if not found.
int64_t with_hashmap_get(void *handle, const void *key, void *out_val, int64_t is_str_key) {
    WithHashMap *m = (WithHashMap *)handle;
    if (hashmap_invalid(m)) {
        void *ra = __builtin_return_address(0);
        fprintf(stderr, "with_hashmap_get: invalid handle=%p ra=%p\n", handle, ra);
        return 0;
    }
    if (with_trace_hashmap_enabled()) {
        int should_trace = 0;
        if (with_hashmap_trace_count < 8) should_trace = 1;
        if ((with_hashmap_trace_count % 10000) == 0) should_trace = 1;
        if (m->key_size > 64 || m->val_size > 64) should_trace = 1;
        if (m->cap > 131072 || m->len > 131072) should_trace = 1;
        if (should_trace) {
            uint8_t b0 = 0;
            uint8_t b1 = 0;
            uint8_t b2 = 0;
            uint8_t b3 = 0;
            if (key && m->key_size > 0) {
                const uint8_t *kb = (const uint8_t *)key;
                b0 = kb[0];
                if (m->key_size > 1) b1 = kb[1];
                if (m->key_size > 2) b2 = kb[2];
                if (m->key_size > 3) b3 = kb[3];
            }
            fprintf(stderr,
                    "[trace-hashmap] get #%lld handle=%p key=%p out=%p key_size=%lld val_size=%lld cap=%lld len=%lld is_str=%lld key_bytes=%u,%u,%u,%u\n",
                    (long long)with_hashmap_trace_count,
                    handle,
                    key,
                    out_val,
                    (long long)m->key_size,
                    (long long)m->val_size,
                    (long long)m->cap,
                    (long long)m->len,
                    (long long)is_str_key,
                    (unsigned)b0,
                    (unsigned)b1,
                    (unsigned)b2,
                    (unsigned)b3);
        }
        with_hashmap_trace_count++;
    }
    uint64_t h = hash_key(key, m->key_size, is_str_key);
    int64_t idx = (int64_t)(h % (uint64_t)m->cap);
    for (int64_t probe = 0; probe < m->cap; probe++) {
        int64_t i = (idx + probe) % m->cap;
        if (m->states[i] == 0) return 0;
        if (m->states[i] == 1 && keys_equal(m->keys + i * m->key_size, key, m->key_size, is_str_key)) {
            memcpy(out_val, m->values + i * m->val_size, m->val_size);
            return 1;
        }
    }
    return 0;
}

int64_t with_hashmap_contains(void *handle, const void *key, int64_t is_str_key) {
    WithHashMap *m = (WithHashMap *)handle;
    if (hashmap_invalid(m)) {
        fprintf(stderr, "with_hashmap_contains: invalid handle=%p\n", handle);
        return 0;
    }
    uint64_t h = hash_key(key, m->key_size, is_str_key);
    int64_t idx = (int64_t)(h % (uint64_t)m->cap);
    for (int64_t probe = 0; probe < m->cap; probe++) {
        int64_t i = (idx + probe) % m->cap;
        if (m->states[i] == 0) return 0;
        if (m->states[i] == 1 && keys_equal(m->keys + i * m->key_size, key, m->key_size, is_str_key))
            return 1;
    }
    return 0;
}

int64_t with_hashmap_remove(void *handle, const void *key, int64_t is_str_key) {
    WithHashMap *m = (WithHashMap *)handle;
    if (hashmap_invalid(m)) {
        fprintf(stderr, "with_hashmap_remove: invalid handle=%p\n", handle);
        return 0;
    }
    uint64_t h = hash_key(key, m->key_size, is_str_key);
    int64_t idx = (int64_t)(h % (uint64_t)m->cap);
    for (int64_t probe = 0; probe < m->cap; probe++) {
        int64_t i = (idx + probe) % m->cap;
        if (m->states[i] == 0) return 0;
        if (m->states[i] == 1 && keys_equal(m->keys + i * m->key_size, key, m->key_size, is_str_key)) {
            m->states[i] = 2;
            m->len--;
            return 1;
        }
    }
    return 0;
}

int64_t with_hashmap_len(void *handle) {
    WithHashMap *m = (WithHashMap *)handle;
    if (hashmap_invalid(m)) {
        fprintf(stderr, "with_hashmap_len: invalid handle=%p\n", handle);
        return 0;
    }
    return m->len;
}

void with_hashmap_free(void *handle) {
    WithHashMap *m = (WithHashMap *)handle;
    free(m->keys);
    free(m->values);
    free(m->states);
    free(m);
}

static void hashmap_grow(WithHashMap *m, int64_t is_str_key) {
    int64_t old_cap = m->cap;
    char *old_keys = m->keys;
    char *old_values = m->values;
    uint8_t *old_states = m->states;
    m->cap = old_cap * 2;
    if (with_trace_hashmap_enabled()) {
        fprintf(stderr,
                "[trace-hashmap] grow handle=%p old_cap=%lld new_cap=%lld key_size=%lld val_size=%lld len=%lld is_str=%lld\n",
                (void *)m,
                (long long)old_cap,
                (long long)m->cap,
                (long long)m->key_size,
                (long long)m->val_size,
                (long long)m->len,
                (long long)is_str_key);
    }
    m->keys = (char *)calloc(m->cap, m->key_size);
    m->values = (char *)calloc(m->cap, m->val_size);
    m->states = (uint8_t *)calloc(m->cap, 1);
    m->len = 0;
    for (int64_t i = 0; i < old_cap; i++) {
        if (old_states[i] == 1) {
            with_hashmap_insert(m, old_keys + i * m->key_size,
                                old_values + i * m->val_size, is_str_key);
        }
    }
    free(old_keys);
    free(old_values);
    free(old_states);
}

void with_hashmap_increment(void *handle, const void *key, int64_t is_str_key) {
    WithHashMap *m = (WithHashMap *)handle;
    if (hashmap_invalid(m)) return;
    int64_t val = 0;
    // Try to get existing value
    if (with_hashmap_get(handle, key, &val, is_str_key)) {
        val++;
    } else {
        val = 1;
    }
    with_hashmap_insert(handle, key, &val, is_str_key);
}

void with_hashmap_decrement(void *handle, const void *key, int64_t is_str_key) {
    WithHashMap *m = (WithHashMap *)handle;
    if (hashmap_invalid(m)) return;
    int64_t val = 0;
    if (with_hashmap_get(handle, key, &val, is_str_key)) {
        val--;
    } else {
        val = -1;
    }
    with_hashmap_insert(handle, key, &val, is_str_key);
}

// ---- std.fs ----

static char *with_str_to_cstring(with_str s) {
    char *buf = (char *)malloc((size_t)s.len + 1);
    if (!buf) return NULL;
    if (s.len > 0 && s.ptr) {
        memcpy(buf, s.ptr, (size_t)s.len);
    }
    buf[s.len] = '\0';
    return buf;
}

// Write text to a file. Returns 0 on success, non-zero on failure.
int32_t with_fs_write_file(with_str path, with_str data) {
    char *cpath = with_str_to_cstring(path);
    if (!cpath) return -1;

    FILE *f = fopen(cpath, "wb");
    free(cpath);
    if (!f) return -1;

    size_t written = 0;
    if (data.len > 0) {
        written = fwrite(data.ptr, 1, (size_t)data.len, f);
    }
    int close_rc = fclose(f);
    if ((int64_t)written != data.len) return -1;
    return close_rc == 0 ? 0 : -1;
}

// Read full file contents into a heap-allocated buffer.
// Returns empty string on failure.
with_str with_fs_read_file(with_str path) {
    with_str out = { "", 0 };
    char *cpath = with_str_to_cstring(path);
    if (!cpath) return out;

    FILE *f = fopen(cpath, "rb");
    free(cpath);
    if (!f) return out;

    if (fseek(f, 0, SEEK_END) != 0) {
        fclose(f);
        return out;
    }
    long size = ftell(f);
    if (size < 0) {
        fclose(f);
        return out;
    }
    if (fseek(f, 0, SEEK_SET) != 0) {
        fclose(f);
        return out;
    }

    char *buf = (char *)malloc((size_t)size + 1);
    if (!buf) {
        fclose(f);
        return out;
    }

    size_t read_n = fread(buf, 1, (size_t)size, f);
    fclose(f);
    if (read_n != (size_t)size) {
        free(buf);
        return out;
    }

    buf[size] = '\0';
    out.ptr = buf;
    out.len = (int64_t)size;
    return out;
}

// ---- std.net ----

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/select.h>

__attribute__((weak)) void with_fiber_yield(void) {
}

__attribute__((weak)) int32_t with_fiber_in_fiber(void) {
    return 0;
}

static int with_net_set_nonblocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) return -1;
    if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) return -1;
    return 0;
}

static void with_net_wait_step(void) {
    if (with_fiber_in_fiber()) {
        with_fiber_yield();
    } else {
        struct timespec ts;
        ts.tv_sec = 0;
        ts.tv_nsec = 1000 * 1000; // 1ms
        nanosleep(&ts, NULL);
    }
}

// Create a TCP socket and bind+listen on given port. Returns fd or -1.
int32_t with_net_tcp_listen(int32_t port, int32_t backlog) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    int opt = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons((uint16_t)port);

    if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    if (listen(fd, backlog) < 0) {
        close(fd);
        return -1;
    }
    if (with_net_set_nonblocking(fd) < 0) {
        close(fd);
        return -1;
    }
    return (int32_t)fd;
}

// Accept a connection on a listening socket. Returns client fd or -1.
int32_t with_net_tcp_accept(int32_t listen_fd) {
    while (1) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        int fd = accept(listen_fd, (struct sockaddr *)&client_addr, &client_len);
        if (fd >= 0) {
            if (with_net_set_nonblocking(fd) < 0) {
                close(fd);
                return -1;
            }
            return (int32_t)fd;
        }

        if (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK) {
            with_net_wait_step();
            continue;
        }
        return -1;
    }
}

// Connect to host:port via TCP. Returns fd or -1.
int32_t with_net_tcp_connect(with_str host, int32_t port) {
    char *chost = with_str_to_cstring(host);
    if (!chost) return -1;

    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    char port_buf[16];
    snprintf(port_buf, sizeof(port_buf), "%d", port);

    if (getaddrinfo(chost, port_buf, &hints, &res) != 0) {
        free(chost);
        return -1;
    }
    free(chost);

    int32_t out_fd = -1;
    for (struct addrinfo *ai = res; ai != NULL; ai = ai->ai_next) {
        int fd = socket(ai->ai_family, ai->ai_socktype, ai->ai_protocol);
        if (fd < 0) continue;

        if (with_net_set_nonblocking(fd) < 0) {
            close(fd);
            continue;
        }

        int rc = connect(fd, ai->ai_addr, ai->ai_addrlen);
        if (rc == 0) {
            out_fd = (int32_t)fd;
            break;
        }

        if (errno == EINPROGRESS || errno == EALREADY || errno == EWOULDBLOCK) {
            while (1) {
                fd_set wfds;
                FD_ZERO(&wfds);
                FD_SET(fd, &wfds);
                struct timeval tv;
                tv.tv_sec = 0;
                tv.tv_usec = 0;
                int sel = select(fd + 1, NULL, &wfds, NULL, &tv);
                if (sel > 0 && FD_ISSET(fd, &wfds)) {
                    int so_err = 0;
                    socklen_t so_len = sizeof(so_err);
                    if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &so_err, &so_len) == 0 && so_err == 0) {
                        out_fd = (int32_t)fd;
                    } else {
                        close(fd);
                    }
                    break;
                }
                if (sel < 0 && errno != EINTR) {
                    close(fd);
                    break;
                }
                with_net_wait_step();
            }
            if (out_fd >= 0) break;
            continue;
        }

        close(fd);
    }

    freeaddrinfo(res);
    return out_fd;
}

// Send data on a socket. Returns bytes sent or -1.
int64_t with_net_send(int32_t fd, with_str data) {
    int64_t sent = 0;
    while (sent < data.len) {
        ssize_t n = send(fd, data.ptr + sent, (size_t)(data.len - sent), 0);
        if (n > 0) {
            sent += (int64_t)n;
            continue;
        }
        if (n == 0) return sent;
        if (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK) {
            with_net_wait_step();
            continue;
        }
        return -1;
    }
    return sent;
}

// Receive data from a socket into a heap buffer. Returns {ptr, len}.
with_str with_net_recv(int32_t fd, int64_t max_len) {
    with_str out = { "", 0 };
    if (max_len <= 0) return out;

    char *buf = (char *)malloc((size_t)max_len + 1);
    if (!buf) return out;

    while (1) {
        ssize_t n = recv(fd, buf, (size_t)max_len, 0);
        if (n > 0) {
            buf[n] = '\0';
            out.ptr = buf;
            out.len = (int64_t)n;
            return out;
        }
        if (n == 0) {
            free(buf);
            return out;
        }
        if (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK) {
            with_net_wait_step();
            continue;
        }
        free(buf);
        return out;
    }
}

// Close a socket.
int32_t with_net_close(int32_t fd) {
    return close(fd);
}

// Create a UDP socket bound to a port. Returns fd or -1.
int32_t with_net_udp_bind(int32_t port) {
    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0) return -1;

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons((uint16_t)port);

    if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    if (with_net_set_nonblocking(fd) < 0) {
        close(fd);
        return -1;
    }
    return (int32_t)fd;
}

// Weak stub for embedded runtime object extraction.
// The real implementation lives in embedded_objects.o (linked into the compiler).
// This stub allows user programs (which link helpers.o but not embedded_objects.o)
// to resolve the symbol without error — it simply returns "not available".
__attribute__((weak))
int32_t with_extract_runtime_obj(with_str name, with_str path) {
    (void)name; (void)path;
    return 1; // not available
}
