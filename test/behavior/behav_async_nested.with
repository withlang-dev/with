//! expect-stdout: ok

async fn inner(x: i32) -> i32:
    x * x

async fn outer(x: i32) -> i32:
    let t = inner(x)
    t.await

async fn main:
    let t = outer(7)
    let r = t.await
    assert(r == 49)
    print("ok")
