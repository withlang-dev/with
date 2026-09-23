//! expect-check-fail: use of moved value

// #1380 (§2.2): the join is an owned temporary whatever consumes it, so an
// observing consumer (a method receiver, `++`, an f-string) still moves the
// arm's binding. `(if c: a else: b).len()` blanked `a` and later reads saw "".
use std.process

fn main:
    let a = "x" ++ "y"
    let b = "u" ++ "v"
    let n = (if args().len() > 0: a else: b).len()
    print(f"{n} [{a}]")
