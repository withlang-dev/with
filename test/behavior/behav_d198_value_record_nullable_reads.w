//! expect-stdout: 12 9

// D198 (§16.2b.5): `nullable param N` composes with `reads` and presents
// `Option[&T]`; `None` crosses as NULL.
use c_import("typedef struct { int w; int h; } Size; static inline int area_or(const Size *s, int fallback) { return s ? s->w * s->h : fallback; }")

c facade shapes:
    fn area_or
        reads param s
        nullable param s

fn main:
    let s = Size { w: 3, h: 4 }
    print(f"{area_or(Some(&s), 9)} {area_or(None, 9)}")
