//! expect-stdout: ok

// The branch-merge union must ACCEPT what is safe: moving on both paths (no use
// after), and reinitializing on both paths (use after). Each Drop runs exactly once
// per the path taken.

type R { id: i32, slot: *mut i32 }
impl Drop for R:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn take(r: R): ()
fn make(slot: *mut i32) -> R: R { id: 1, slot }

// Moved on both branches; r is consumed on whichever path runs (1 drop).
fn both_move(d: bool, slot: *mut i32):
    let r = make(slot)
    if d:
        take(r)
    else:
        take(r)

// Reinitialized on both branches; r is live after the if (drop old on reassign +
// drop the replacement at take = 2 drops).
fn both_reinit(d: bool, slot: *mut i32):
    var r = make(slot)
    if d:
        r = make(slot)
    else:
        r = make(slot)
    take(r)

fn main:
    var drops = 0
    both_move(true, &raw mut drops)
    both_move(false, &raw mut drops)
    both_reinit(true, &raw mut drops)
    both_reinit(false, &raw mut drops)
    assert(drops == 6)
    print("ok")
