//! expect-check-fail: type mismatch in binding

// #1464 (§14.4): a call of an `async fn` is a `Task[T]`; the T is `.await`'s.
// The inferred return was stored bare, so this compiled and printed the task
// handle's fiber id.
async fn double(x: i32): x * 2

fn main:
    let x: i32 = double(5)
    print(x)
