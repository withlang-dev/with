//! expect-check-fail: 'from buf_load, nonnull field inner': Buf has no field inner

// §16.2b.13: the field path is checked against the record.
use c_import("void free(void *p);
typedef struct { int *data; int n; } Buf;
Buf buf_load(int n);
void buf_free(Buf b);
")

c facade bufs:
    resource Buffer wraps Buf
        from buf_load, nonnull field inner.data
        drop buf_free

fn main:
    print("x")
