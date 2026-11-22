//! expect-check-fail: at compile time: it belongs to another package (ctlib) and is not declared `comptime fn`
// A method is a function: an unmarked one of another package is refused.
use ctlib.math

const TWELVE: i32 = comptime Pair { a: 3, b: 4 }.product()

fn main:
    print(f"{TWELVE}")
