//! expect-check-fail: resource 'Stream' names both 'from' and 'init'

// D51 §16.2b.4 stage 4b: a resource is produced one way — direct return,
// out parameter, or in-place initialization — never two.

use c_import("typedef struct { int state; } z_stream;
z_stream z_new(void);
int z_init(z_stream* s);
void z_end(z_stream* s);
")

c facade zl:
    resource Stream wraps z_stream
        from z_new
        init z_init(self)
        drop z_end

fn main:
    print("ok")
