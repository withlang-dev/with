//! expect-check-fail: is reached as `.repr` under the raw C rules and requires unsafe context
// D198 (§16.2b.3): the record itself is reached as .repr, under the raw C rules; it copied out a second handle to the same buffer in safe code.
use c_import("typedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = 0; i.n = 4; return i; } static inline void img_free(Img i) { } static inline int img_count(Img i) { return i.n; }")

c facade imgs:
    resource Picture wraps Img
        from img_new
        drop img_free

fn main:
    let image = img_new()
    let raw = image.repr
    print(f"{raw.n}")
