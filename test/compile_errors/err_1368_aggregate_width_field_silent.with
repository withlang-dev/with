//! expect-error: type mismatch in struct literal field 't': expected (i64, i64), got (i32, i32)

// #1368: a struct field initialized with a narrower tuple compiled and read
// garbage (17179869187 for `(3, 4)`): a silent wrong value, now a Sema error.
type P { t: (i64, i64) }
fn pair -> (i32, i32): (3, 4)
fn main:
    let p = P { t: pair() }
    print(f"{p.t.0}")
