//! expect-check-fail: 'preinit z_storage' and 'init z_init' both take a parameter named 'level'

// D51 §16.2b.4 stage 4b: the in-place constructor takes the preinit
// operation's parameters and then the initializer's; a C name both spell
// would be one With parameter with two meanings, so it is refused at the
// resource rather than surfacing as a shadowing error in rendered code.

use c_import("typedef struct { int state; } z_stream;
z_stream z_storage(int level);
int z_init(z_stream* s, int level);
void z_end(z_stream* s);
")

c facade zl:
    resource Stream wraps z_stream
        preinit z_storage
        init z_init(self)
        drop z_end

fn main:
    print("ok")
