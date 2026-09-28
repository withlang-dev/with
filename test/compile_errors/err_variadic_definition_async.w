//! expect-check-fail: a function defined with `...` has the C calling convention, so it cannot be async or a generator

// D75 (§16.2b.5): a `...` definition has the C calling convention; an async
// function has the compiler's own.
async fn tally(n: i32, ...) -> i32: n

fn main:
    print("unreached")
