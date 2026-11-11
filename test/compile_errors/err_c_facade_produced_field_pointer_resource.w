//! expect-check-fail: names a field of a record passed by value

// §16.2b.4: a pointer resource's NULL is the representation's own.
use c_import("typedef struct Buf { int *data; } Buf;
Buf *buf_open(int n);
void buf_close(Buf *b);
")

c facade bufs:
    resource Buffer wraps *mut Buf
        from buf_open, nullable field data
        drop buf_close

fn main:
    print("x")
