//! expect-check-fail: is described twice; a value record has one of `reads`, `fills`, `updates` (§16.2b.5)
// D198 (§16.2b.5): one clause per value record.
use c_import("typedef struct { int w; int h; } Size; static inline void grow(Size *s, int by) { s->w += by; }")

c contract shapes:
    fn grow
        reads param s
        updates param s

fn main:
    print("unreachable")
