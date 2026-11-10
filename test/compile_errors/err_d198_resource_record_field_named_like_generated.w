//! expect-check-fail: its record has a field named 'live', which the type generated for the resource keeps for itself
// D198 (§16.2b.3): a record field with the name of a field the generated
// type keeps is two meanings for one spelling; the facade is refused.
use c_import("typedef struct { int *data; int live; } Img; static inline Img img_new(void) { Img i; i.data = 0; i.live = 4; return i; } static inline void img_free(Img i) { }")

c facade imgs:
    resource Picture wraps Img
        from img_new
        drop img_free

fn main:
    print("unreachable")
