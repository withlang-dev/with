// With Language Runtime Helpers
// Small C wrapper functions for stdlib features that need special handling.

#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#ifdef __APPLE__
#include <crt_externs.h>
#endif

// Common string type used across runtime helpers
typedef struct {
    const char *ptr;
    int64_t len;
} with_str;

typedef struct {
    char *buf;
    int64_t len;
    int64_t cap;
} with_str_builder;

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
#ifdef __APPLE__
    int *argc_ptr = _NSGetArgc();
    return argc_ptr ? (int32_t)(*argc_ptr) : 0;
#else
    return 0;
#endif
}

// Command-line argument at index. Returns "" when out of range.
with_str with_arg_at(int32_t idx) {
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

void *with_hashmap_new(int64_t key_size, int64_t val_size) {
    WithHashMap *m = (WithHashMap *)calloc(1, sizeof(WithHashMap));
    m->cap = 16;
    m->key_size = key_size;
    m->val_size = val_size;
    m->keys = (char *)calloc(16, key_size);
    m->values = (char *)calloc(16, val_size);
    m->states = (uint8_t *)calloc(16, 1);
    return m;
}

void with_hashmap_insert(void *handle, const void *key, const void *val, int64_t is_str_key) {
    WithHashMap *m = (WithHashMap *)handle;
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
    return ((WithHashMap *)handle)->len;
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
        usleep(1000);
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
