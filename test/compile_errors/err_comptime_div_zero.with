//! expect-check-fail: division by zero in comptime

comptime fn explode() -> i32:
    1 / 0

fn main:
    let bad: i32 = comptime explode()
    assert(bad == 0)
