//! expect-check-fail: cannot evaluate 'second_of' at compile time: it belongs to another package (ctlib) and is not declared `comptime fn`
// A generic function is a function: unmarked in the other package.
use ctlib.math

const X: i32 = comptime second_of(1, 2)

fn main:
    print(f"{X}")
