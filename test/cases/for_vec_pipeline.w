//! expect-stdout: ok

// Test: Vec pipeline with sum.

use std.iter

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)

    let total = sum(v)
    assert(total == 60)

    // Pipeline style
    let v2: Vec[i32] = Vec.new()
    v2.push(5)
    v2.push(15)
    let total2 = v2 |> sum
    assert(total2 == 20)

    println("ok")

fn is_even(x: i32) -> bool:
    x % 2 == 0
