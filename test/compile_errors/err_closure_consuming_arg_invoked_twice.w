//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): a closure that consumes its capture is call-once, so it may
// only be handed to a callee that invokes its parameter at most once —
// proved from the callee's body. `twice` calls `f` twice.
fn twice(f: fn() -> str) -> str:
    let a = f()
    let b = f()
    a ++ b

fn main:
    let s = "abc".clone()
    print(twice(() => s))
