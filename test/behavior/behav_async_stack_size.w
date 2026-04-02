//! expect-stdout: ok

@[stack_size(131072)]
async fn compute(x: i32) -> i32:
    x * x

async fn main:
    let t = compute(7)
    let r = t.await
    assert(r == 49)
    print("ok")
