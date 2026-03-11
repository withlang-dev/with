//! expect-stdout: ok

// Test: pipeline operator with functions

fn triple(x: i32) -> i32:
    x * 3

fn sub_one(x: i32) -> i32:
    x - 1

fn main:
    // Basic pipeline
    let a = 4 |> triple
    assert(a == 12)

    // Chained pipeline
    let b = 10 |> sub_one |> triple
    assert(b == 27)

    println("ok")
