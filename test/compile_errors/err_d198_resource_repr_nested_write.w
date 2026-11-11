//! expect-check-fail: cannot assign a field of 'Picture', a type the facade renders
// §16.2b.3: a write to a place inside a resource's representation puts an
// address the program chose under its safe surface, as a write to the
// representation itself does. Drop handed C the forged pointer.
use c_import("#include <stdlib.h>\ntypedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = malloc(16); i.n = 4; return i; } static inline void img_free(Img i) { free(i.data); }")

c contract imgs:
    resource Picture wraps Img
        from img_new
        drop img_free

fn main:
    var p = Picture.new()
    p.repr.data = 4096 as *mut i32
