//! expect-check-fail: this call stores a view of `x` into `h` through its shared receiver, and `h` outlives this call

// #1778 (§21.1, D22): `with guard as mut v` hands `v`'s final value back to
// the mutex (`enter_mut` through `&self`, ScopedMut.with_exit_mut) — a store
// into the caller's `H`, as `Mutex.set` is. A view of the local `x` there
// would dangle once `keep` returns.
use std.sync
type H = ephemeral { slot: Mutex[Option[&i32]] }
fn keep(h: &H):
    let x = 5
    with h.slot.enter_mut() as mut v:
        v = Some(&x)
        print("stored")
fn main:
    let h = H { slot: Mutex.new(None) }
    keep(h)
    print("unreachable")
