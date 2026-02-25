// Test: std.random import
use std.random

fn main() -> i32 =
    seed(12345)
    let a = next_i32()
    assert(a >= 0)

    let b = range_i32(10, 20)
    assert(b >= 10)
    assert(b < 20)

    assert(chance(100))
    assert(not chance(0))

    seed_now()
    let c = next_i32()
    assert(c >= 0)
    0
