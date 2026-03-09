//! expect-stdout: ok

// Test: tuple concurrent await — spawn two tasks, await both as a tuple.

async fn double(x: i32) -> i32:
    x * 2

async fn triple(x: i32) -> i32:
    x * 3

fn main:
    // Spawn two tasks
    let t1 = double(5)
    let t2 = triple(4)

    // Tuple await
    let (a, b) = (t1, t2).await
    assert(a == 10)
    assert(b == 12)

    // Direct tuple await
    let (c, d) = (double(1), triple(1)).await
    assert(c == 2)
    assert(d == 3)

    println("ok")
