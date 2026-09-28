//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): the body's invocation count survives a call to a generic
// function between the two calls. The specialization of `id` is checked in
// the middle of `apply`'s body and reset its counts, so `apply` counted one
// call of `f`.
fn id[T](x: T) -> T: x

fn apply(f: fn() -> str) -> str:
    let a = f()
    let k = id(1)
    a ++ f()

fn main:
    let s = "abc".clone()
    print(apply(() => s))
