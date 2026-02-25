// With Language Runtime Helpers
// Small C wrapper functions for stdlib features that need special handling.

#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

// time(NULL) wrapper — Zig/LLVM has trouble with NULL pointer args
int64_t with_time_now(void) {
    return (int64_t)time(NULL);
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
