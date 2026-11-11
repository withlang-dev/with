//! expect-exit: 134
//! expect-stderr: buf_take: the facade states 'nonnull field data', and C returned it NULL

// §16.2b.4: under `nonnull field F` a NULL there is a contract failure
// naming the function, so an invalid resource never exists.
use c_import("void free(void *p);
typedef struct { int *data; int n; } Buf;
static inline Buf buf_take(int n) { Buf b; b.n = n; b.data = 0; return b; }
static inline void buf_free(Buf b) { free(b.data); }
")

c facade bufs:
    resource Buffer wraps Buf
        from buf_take, nonnull field data
        drop buf_free

fn main:
    let b = buf_take(4)
    print(f"{b.n}")
