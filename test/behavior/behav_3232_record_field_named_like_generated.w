//! expect-stdout: 7 3

// #3232 (§16.2b.3): the type a facade generates for a resource keeps fields
// of its own (its liveness flag is `live`). They belong to its generated
// code, so a C record with a field of that name is read as any other:
// `p.live` is the record's field. The facade was refused instead.
use c_import("typedef struct { int *data; int live; int n; } Img; static inline Img img_new(void) { Img i; i.data = 0; i.live = 7; i.n = 3; return i; } static inline void img_free(Img i) { }")

c facade imgs:
    resource Picture wraps Img
        from img_new
        drop img_free

fn main:
    let p = img_new()
    print(f"{p.live} {p.n}")
