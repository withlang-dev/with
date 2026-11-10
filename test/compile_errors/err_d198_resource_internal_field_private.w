//! expect-check-fail: 'live' is a field of the type the facade generates for 'Picture' and belongs to its generated code
// D198 (§16.2b.3): the fields of a type a facade generates belong to its
// generated code. Outside it a program reads the record's fields through
// the resource and names only `.repr`, in `unsafe`.
use c_import("typedef struct { int *data; int n; } Img; static inline Img img_new(void) { Img i; i.data = 0; i.n = 4; return i; } static inline void img_free(Img i) { }")

c facade imgs:
    resource Picture wraps Img
        from img_new
        drop img_free

fn main:
    let image = img_new()
    print(f"{image.live}")
