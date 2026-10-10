//! expect-stdout: ok

// #696: a Drop value moved *before* a loop must not be flagged by the loop's
// `continue` back-edge check. The continue check used to fire on "moved at the
// continue" alone, ignoring the loop-entry state, so a pre-loop move (already
// MOVED at entry, never touched inside the loop) was wrongly reported as
// "moved inside a loop and not reinitialized". It now applies the same
// entry==LIVE guard the fall-through back-edge (finalize_loop_move_state) uses.

type D { id: i32 }
impl Drop for D:
    fn drop(move self: Self): ()

fn consume(d: D): ()

fn f(n: i32) -> i32:
    let fresh = D { id: 1 }
    consume(move fresh)        // moved before the loop; never used inside it
    var seen: i32 = 0
    for i in 0..n:
        if i > 0:
            continue           // back-edge: `fresh` was already MOVED at entry
        seen = seen + 1
    seen

fn main:
    assert(f(3) == 1)
    print("ok")
