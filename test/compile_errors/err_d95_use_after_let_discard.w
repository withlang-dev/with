//! expect-error: `let _ = h` dropped `h` at line 6; remove it to keep `h`
// §29.6 (D95, #2074): `_` binds nothing, so `let _ = h` moves a non-Copy
// `h` and drops it there; a later use is a use of a moved value. It used to
// compile and read freed memory.
fn f(h: str) -> i64:
    let _ = h
    h.len()

fn main: print(f("abc".to_upper()))
