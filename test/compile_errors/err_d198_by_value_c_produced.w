//! expect-check-fail: takes `Img` by value, and field 'data'
// D198 (§16.2b.5): no forged pointer is needed. A record C produced is copied by safe code and destroyed twice; the by-value call is the gate.
use c_import("#include <stdlib.h>\ntypedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = malloc(sizeof(int) * 4); i.data[0] = 7; i.n = 4; return i; } static inline void img_free(Img i) { free(i.data); } static inline int img_get(Img i) { return i.data[0]; }")

fn main:
    let img = img_new()
    print(f"{img_get(img)}")
    img_free(img)
    img_free(img)
    print(f"{img_get(img)}")
