//! expect-check-fail: its record has a field named 'repr', which the resource keeps for itself
// D198 (§16.2b.3): `.repr` is the raw spelling of the record; a record field of that name is a facade error.
use c_import("typedef struct { int *repr; int n; } Img; static inline Img img_new(void) { Img i; i.repr = 0; i.n = 4; return i; } static inline void img_free(Img i) { }")

c facade imgs:
    resource Picture wraps Img
        from img_new
        drop img_free

fn main:
    print("unreachable")
