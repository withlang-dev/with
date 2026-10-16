//! expect-check-fail: use of moved value

// #1380 (§2.2): the join is an owned temporary whatever consumes it, so an
// observing consumer (a method receiver) still moves the arm's binding.
// `(if c: a else: b).len()` blanked `a` and later reads saw an empty value.
// A List, not a str: a str is a value and is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
use std.process

fn main:
    let a: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }]
    let b: List[Tok] = [Tok { id: 3 }]
    let n = (if args().len() > 0: a else: b).len()
    print(f"{n} [{a.len()}]")
