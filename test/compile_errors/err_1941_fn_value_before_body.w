//! expect-check-fail: cannot format a value of type 'fn(i32) -> i32' with :?

// #1941 class (D43, §4.10): a function written without a return type has
// the type its body gives it; used as a value before its body was checked,
// `twice` read as fn(i32) -> Unit.
use std.rc.Rc

fn main:
    let op = Rc.new(twice)
    print(f"{op:?}")

fn twice(x: i32): x * 2
