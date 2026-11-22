//! expect-stdout: ok

async fn compute(x: i32) -> i32:
    x * x

async fn main:
    let t1 = compute(5)
    let t2 = compute(7)
    // Await both — they complete
    let r1 = t1.await
    let r2 = t2.await
    // Cancelling already-completed tasks is a no-op
    assert(r1 == 25)
    assert(r2 == 49)
    print("ok")
