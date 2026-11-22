//! expect-stdout: ok

// Test ? operator inside async function body.
// Uses sync function for the Result, async for the caller.

fn divide(a: i32, b: i32) -> Option[i32]:
    if b == 0:
        return None
    Some(a / b)

async fn compute() -> i32:
    let r = divide(10, 2)
    if r.is_some():
        return r.unwrap()
    0

async fn main:
    let t = compute()
    let val = t.await
    assert(val == 5)
    print("ok")
