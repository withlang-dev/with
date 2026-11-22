//! expect-check-fail: the pointer is `const`, so the callee cannot write the record; `reads` is the clause (§16.2b.5)
//! expect-check-fail: = help: write `reads` in place of `updates`
// D198 (§16.2b.5): `updates` and `fills` need a pointer the callee may write through.
use c_import("typedef struct { int w; int h; } Size; static inline int area(const Size *s) { return s->w * s->h; }")

c contract shapes:
    fn area
        updates param s

fn main:
    print("unreachable")
