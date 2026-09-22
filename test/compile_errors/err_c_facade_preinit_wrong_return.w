//! expect-check-fail: 'preinit z_storage' returns Unit, not the representation; preinit constructs the storage that init fills

// D51 ruling §13.1 stage 4b: `preinit` constructs the storage `init` fills,
// standing where `Representation.zeroed()` would — so it returns the
// representation. An operation that fills a pointer instead is not that.

use c_import("typedef struct { int state; } z_stream;
void z_storage(z_stream* s);
int z_init(z_stream* s);
void z_end(z_stream* s);
")

c facade zl:
    resource Stream wraps z_stream
        preinit z_storage
        init z_init(self)
        drop z_end

fn main:
    print("ok")
