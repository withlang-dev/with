//! expect-stdout: ok

async fn double(x: i32) -> i32:
    x * 2

async fn triple(x: i32) -> i32:
    x * 3

async fn main:
    let t1 = double(5)
    let t2 = triple(4)
    let (a, b) = (t1, t2).await
    assert(a == 10)
    assert(b == 12)
    print("ok")
