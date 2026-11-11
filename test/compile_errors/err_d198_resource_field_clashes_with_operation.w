//! expect-check-fail: its record's field 'n' and the operation 'img_n', presented as 'n', would both be
// D198 (§16.2b.3): a record field with the name of a presented operation is a facade error; neither silently wins.
use c_import("typedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = 0; i.n = 4; return i; } static inline void img_free(Img i) { } static inline int img_n(Img i) { return i.n; }")

c contract imgs:
    resource Picture wraps Img
        from img_new
        drop img_free
    fn img_n
        of Picture

fn main:
    print("unreachable")
