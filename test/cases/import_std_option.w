// Test: std.option import
use std.option

fn is_positive(x: i32) -> bool =
    x > 0

fn main() -> i32 =
    let a: Option[i32] = Some(5)
    assert(is_some(a))
    assert(not is_none(a))
    assert(unwrap_or(a, 0) == 5)

    let b: Option[i32] = Some(-3)
    let f = filter(b, is_positive)
    assert(is_none(f))

    let c: Option[i32] = None
    assert(is_none(c))
    assert(unwrap_or(c, 42) == 42)
    0
