//! expect-check-fail: at compile time: it belongs to another package (ctlib) and is not declared `comptime fn`
// An operator is a function: `-` is `Sub.sub`, unmarked in the other package.
use ctlib.math

const X: i32 = comptime (Money { cents: 9 } - Money { cents: 4 }).cents

fn main:
    print(f"{X}")
