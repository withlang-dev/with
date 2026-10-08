//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): a closure that consumes its capture is call-once, so it may
// only be handed to a callee that invokes its parameter at most once —
// proved from the callee's body. `twice` calls `f` twice.
// A Vec capture, not a str: a str capture is copied (D111).
fn twice(f: fn() -> Vec[i32]) -> i64:
    let a = f()
    let b = f()
    a.len() + b.len()

fn main:
    let s: Vec[i32] = [1, 2, 3]
    print(twice(() => s))
