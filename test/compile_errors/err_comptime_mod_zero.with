//! expect-check-fail: modulo by zero in comptime

comptime fn mod_zero() -> i32:
    10 % 0

fn main:
    let bad: i32 = comptime mod_zero()
    assert(bad == 0)
