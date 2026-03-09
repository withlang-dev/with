//! expect-stdout: ok

// Test: Vec iterator pipeline with iter_sum.

use std.iter
use std.collections

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)

    // Direct sum (existing Vec-based function)
    let total1 = sum(v)
    assert(total1 == 60)

    // Iterator-based sum
    let iter = vec_iter_i32(v)
    let total2 = iter_sum(iter)
    assert(total2 == 60)

    // Pipeline: vec_iter_i32 |> iter_sum
    let total3 = vec_iter_i32(v) |> iter_sum
    assert(total3 == 60)

    println("ok")
