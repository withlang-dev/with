//! expect-check-fail: which states the field: 'nonnull field <F>'
//! expect-check-fail: = help: write 'from buf_load, nonnull field <F>', with <F> the pointer field that is never NULL

// #3129 (§31.8.2): a record passed by value has no NULL of its own; the
// word names the pointer field.
use c_import("void free(void *p);\ntypedef struct { int *data; int n; } Buf;\nBuf buf_load(int n);\nvoid buf_free(Buf b);\n")

c contract bufs:
    resource Buffer wraps Buf
        from buf_load, nonnull
        drop buf_free

fn main:
    print("unreachable")
