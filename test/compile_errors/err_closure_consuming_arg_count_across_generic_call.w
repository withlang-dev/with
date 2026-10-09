//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): the body's invocation count survives a call to a generic
// function between the two calls. The specialization of `id` is checked in
// the middle of `apply`'s body and reset its counts, so `apply` counted one
// call of `f`. A List capture, not a str: a str capture is copied (D111).
fn id[T](x: T) -> T: x

fn apply(f: fn() -> List[i32]) -> i64:
    let a = f()
    let k = id(1)
    a.len() + f().len()

fn main:
    let s: List[i32] = [1, 2, 3]
    print(apply(() => s))
