//! expect-check-fail: 'ok Z_OK' compares an integer status, but 'init z_init' returns f64

// D51 stage 5, spec §16.2b.4/§16.2b.13: an in-place initializer's `ok`
// compares its status with an imported integer constant, so the status is
// an integer.

use c_import("typedef struct { int state; } z_stream;
#define Z_OK 0
double z_init(z_stream* s);
void z_end(z_stream* s);
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        ok Z_OK
        drop z_end

fn main:
    print("ok")
