//! expect-stdout: 12 20 4 5

// D198 (§16.2b.5 "Value records", §16.2b.11): a pointer parameter to one
// complete record that is not a resource's representation is described by
// what the callee does with the record. `reads param N` presents a `&T`
// argument; `updates param N` presents a `mut` parameter (D172), whose
// place the callee writes. Without the clause both calls are raw.
use c_import("typedef struct { int w; int h; } Size; static inline int area(const Size *s) { return s->w * s->h; } static inline void grow(Size *s, int by) { s->w += by; s->h += by; }")

c facade shapes:
    fn area
        reads param s
    fn grow
        updates param s

fn main:
    var s = Size { w: 3, h: 4 }
    let before = area(s)
    grow(s, 1)
    print(f"{before} {area(s)} {s.w} {s.h}")
