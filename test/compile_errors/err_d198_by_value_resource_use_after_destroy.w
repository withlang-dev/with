//! expect-check-fail: use of moved value
// D198 (§16.2b.3, §16.2b.11): a by-value token's operations under their imported names are the resource's. The explicit destroyer consumes it.
use c_import("#include <stdlib.h>\ntypedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = malloc(sizeof(int) * 4); i.data[0] = 7; i.n = 4; return i; } static inline void img_free(Img i) { free(i.data); } static inline int img_get(Img i, int k) { return i.data[k]; }")

c facade imgs:
    resource Picture wraps Img
        from img_new
        drop img_free
    fn img_get
        of Picture

fn main:
    let image = img_new()
    img_free(image)
    print(f"{img_get(image, 0)}")
