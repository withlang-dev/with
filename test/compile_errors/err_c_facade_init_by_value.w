//! expect-check-fail: 'init z_init' takes the representation by value, so it would initialize a copy

// D51 §16.2b.4 stage 4b: an in-place initializer fills caller-allocated
// storage, so it takes a pointer to the representation; one that takes the
// struct by value would initialize a copy the resource never sees.

use c_import("typedef struct { int state; } z_stream;
int z_init(z_stream s);
void z_end(z_stream* s);
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        drop z_end

fn main:
    print("ok")
