//! expect-check-fail: a function defined with `...` has the C calling convention, so it cannot be async or a generator
//! expect-check-fail: a function defined with `...` has the C calling convention, so it cannot be generic

// D75 (§16.2b.5): a `...` definition has the C calling convention — one C
// signature. An async function has the compiler's own convention, and a
// generic function is a template each caller instantiates.
async fn tally(n: i32, ...) -> i32: n

unsafe fn scaled[T](base: T, n: i32, ...) -> i32: n

fn main:
    print("unreached")
