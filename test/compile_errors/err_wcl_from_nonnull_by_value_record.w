//! expect-check-fail: 'from buf_load, nonnull' is for a producer that returns a pointer

// §31.8.2: a record passed by value has no NULL of its own; it states the
// field whose NULL means nothing was produced.
use c_import("typedef struct { int *data; int n; } Buf;
Buf buf_load(int n);
void buf_free(Buf b);
")

c contract bufs:
    resource Buffer wraps Buf
        from buf_load, nonnull
        drop buf_free

fn main:
    print("x")
