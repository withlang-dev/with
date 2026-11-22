//! expect-stdout: ok

async fn add(a: i32, b: i32) -> i32:
    a + b

async fn main:
    let t1 = add(10, 20)
    let t2 = add(30, 40)
    let r1 = t1.await
    let r2 = t2.await
    assert(r1 == 30)
    assert(r2 == 70)
    print("ok")
