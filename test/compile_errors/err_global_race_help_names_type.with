//! expect-check-fail: = help: use Atomic[i32], wrap in Mutex, or assert with `unsafe`
// §9.1c: the failed single-thread proof names the construct that introduced
// concurrency (the label on the async call) and offers the remedies for the
// global's own type, exactly as the spec's worked example shows.

global var counter: i32 = 0

async fn handle(n: i32) -> i32:
    counter += 1
    n

fn main:
    let t = handle(1)
    let _ = t.await
