//! expect-check-fail: may outlive its origin 'extra'

// #1638 / §12.4: a struct literal holding a non-move closure over a local
// is an ephemeral value; returning it would let the closure outlive
// `extra`. The fix-it is `move x => x + k`.
type Cnt { name: str, f: fn(i32) -> i32 }
fn mk(k: i32) -> Cnt:
    let extra = k
    Cnt { name: "n", f: x => x + extra }
fn main:
    let c = mk(100)
    print(c.f(1))
