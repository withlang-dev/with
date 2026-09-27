//! expect-check-fail: this call stores a view of `x` into `h` through its shared receiver, and `h` outlives this call: `x` does not live past this call

// #1778 (§21.1, D22): `Mutex.set` stores through a `&self` receiver —
// interior mutability — so no mutation of the receiver place shows the
// store. A view of the local `x` put into the caller's `H` would dangle
// once `keep` returns; the store is refused.
use std.sync

type H = ephemeral { slot: Mutex[Option[&i32]] }

fn keep(h: &H):
    let x = 5
    h.slot.set(Some(&x))

fn main:
    let h = H { slot: Mutex.new(None) }
    keep(h)
    print("unreachable")
