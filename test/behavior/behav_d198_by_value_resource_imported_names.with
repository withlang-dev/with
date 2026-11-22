//! expect-stdout: 7 7 3

// D198 (§16.2b.3, §16.2b.11): a by-value token's operations are presented
// under their imported names over the resource: the producer yields it, an
// operation borrows it, the explicit destroyer consumes it, and a value
// never destroyed is dropped by its scope. A flat record by value is safe.
use c_import("#include <stdlib.h>\ntypedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = malloc(sizeof(int) * 4); i.data[0] = 7; i.n = 4; return i; } static inline void img_free(Img i) { free(i.data); } static inline int img_get(Img i, int k) { return i.data[k]; } typedef struct { int x; int y; } Pt; static inline int pt_sum(Pt p) { return p.x + p.y; }")

c contract imgs:
    resource Picture wraps Img
        from img_new
        drop img_free
    fn img_get
        of Picture

fn scoped() -> i32:
    let image = img_new()
    img_get(image, 0)

fn main:
    let image = img_new()
    let first = img_get(image, 0)
    img_free(image)
    print(f"{first} {scoped()} {pt_sum(Pt { x: 1, y: 2 })}")
