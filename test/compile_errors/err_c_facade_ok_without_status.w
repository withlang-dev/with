//! expect-check-fail: 'ok Z_OK' names a status but 'init z_init' returns nothing to compare it with

// D51 §16.2b.4 stage 4b: `ok` interprets the initializer's status; a void
// initializer has none, so the clause states nothing the compiler can read.

use c_import("typedef struct { int state; } z_stream;
#define Z_OK 0
void z_init(z_stream* s);
void z_end(z_stream* s);
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        ok Z_OK
        drop z_end

fn main:
    print("ok")
