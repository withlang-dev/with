//! expect-check-fail: wrong argument type in call to 'apply64'

// #1772: an integer result of another width is a different signature — the
// i32 result was read as an i64 (printed 4294967287 for -9).

fn add1(x: i32) -> i32: x + 1
fn apply64(f: fn(i32) -> i64, v: i32) -> i64: f(v)

fn main:
    print(apply64(add1, -10))
