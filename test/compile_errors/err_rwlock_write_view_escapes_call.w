//! expect-check-fail: this call stores a view of `x` into `h` through its shared receiver, and `h` outlives this call

// #1778 (§21.1, D22): `RwLock.write` stores through a `&self` receiver, as
// `Mutex.set` does; a view of a local put into the caller's lock is refused.
use std.sync
type H = ephemeral { lock: RwLock[Option[&i32]] }
fn keep(h: &H):
    let x = 5
    h.lock.write(Some(&x))
fn main:
    let h = H { lock: RwLock.new(None) }
    keep(h)
    print("unreachable")
