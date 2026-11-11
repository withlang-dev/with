//! expect-check-fail: cannot assign a field of 'Picture'
// D198 (§16.2b.3): fields are not assigned through the resource.
use c_import("typedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = 0; i.n = 4; return i; } static inline void img_free(Img i) { } static inline int img_count(Img i) { return i.n; }")

c contract imgs:
    resource Picture wraps Img
        from img_new
        drop img_free

fn main:
    var image = img_new()
    image.n = 5
