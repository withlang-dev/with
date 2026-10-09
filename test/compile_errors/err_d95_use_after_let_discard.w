//! expect-error: `let _ = h` dropped `h` at line 7; remove it to keep `h`
// §29.6 (D95, #2074): `_` binds nothing, so `let _ = h` moves a non-Copy
// `h` and drops it there; a later use is a use of a moved value. It used to
// compile and read freed memory. A List, not a str: a str is copied (D111).
use std.builtins.print_i64
fn f(h: List[i32]) -> i64:
    let _ = h
    h.len()

fn main: print_i64(f([1, 2, 3]))
