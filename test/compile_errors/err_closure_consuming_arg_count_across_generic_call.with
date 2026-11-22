//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): the body's invocation count survives a call to a generic
// function between the two calls. The specialization of `id` is checked in
// the middle of `apply`'s body and reset its counts, so `apply` counted one
// call of `f`. A List capture, not a str: a str capture is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn id[T](x: T) -> T: x

fn apply(f: fn() -> List[Tok]) -> i64:
    let a = f()
    let k = id(1)
    a.len() + f().len()

fn main:
    let s: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }, Tok { id: 3 }]
    print(apply(() => s))
