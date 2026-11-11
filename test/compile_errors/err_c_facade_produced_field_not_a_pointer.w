//! expect-check-fail: 'from buf_load, nullable field n': the field is i32, not a pointer

// §16.2b.4: only a pointer has a NULL that means nothing was produced.
use c_import("void free(void *p);
typedef struct { int *data; int n; } Buf;
Buf buf_load(int n);
void buf_free(Buf b);
")

c contract bufs:
    resource Buffer wraps Buf
        from buf_load, nullable field n
        drop buf_free

fn main:
    print("x")
