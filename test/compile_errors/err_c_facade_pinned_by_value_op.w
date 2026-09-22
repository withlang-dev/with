//! expect-check-fail: 'z_end' takes the representation by value, but an in-place resource is pinned

// Spec §16.2b.3, D54: a pinned resource's representation lives in its cell
// and every operation reaches it by address; a destroyer taking the struct
// by value would act on a copy of a representation whose address the
// library may keep. The facade says `movable` if it may be copied.

use c_import("typedef struct { int state; } z_stream;
int z_init(z_stream* s);
void z_end(z_stream s);
")

c facade zl:
    resource Stream wraps z_stream
        init z_init(self)
        drop z_end

fn main:
    print("ok")
