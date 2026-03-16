//! skip: async is a separate feature project
//! expect-stdout: ok

// Test: async function declaration, spawn, await, and result passing.

async fn compute(x: i32) -> i32:
    x * 2 + 1

async fn add(a: i32, b: i32) -> i32:
    a + b

fn main:
    // Single await
    let t1 = compute(5)
    let r1 = t1.await
    assert(r1 == 11)

    // Multi-param async
    let t2 = add(10, 20)
    let r2 = t2.await
    assert(r2 == 30)

    // Direct await
    let r3 = compute(0).await
    assert(r3 == 1)

    println("ok")
