//! expect-stdout: 0 0
//! expect-stdout: 0 0

// #2636: `T.zeroed()` is a value (§16.2b.3), not the reset-on-move blank.
// Lowered as the same `const zst(T)` the blank is, a zeroed value bound to
// a local and returned read as "killed" to the use-after-kill validator and
// as `Reset` to the drop-state tracker (`audit:all` failed on hello world
// through the in-unit stc corpus's `end()`); it is its own constant now.
@[repr(C)]
type Pair { left: i64, right: u8 }

fn fresh():
    let z = Pair.zeroed()
    z

fn main:
    let p = fresh()
    print(f"{p.left} {p.right}")
    let q = Pair.zeroed()
    print(f"{q.left} {q.right}")
