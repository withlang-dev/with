//! expect-check-fail: invokes its parameter more than once

// D63 (§12.4): a closure that consumes its capture is call-once, so it may
// only be handed to a callee that invokes its parameter at most once —
// proved from the callee's body. `twice` calls `f` twice.
// A List capture, not a str: a str capture is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn twice(f: fn() -> List[Tok]) -> i64:
    let a = f()
    let b = f()
    a.len() + b.len()

fn main:
    let s: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }, Tok { id: 3 }]
    print(twice(() => s))
