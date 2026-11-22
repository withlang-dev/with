//! expect-stdout: ok

// §3.8: the signature states parameter ownership mode. A callee that only
// reads declares `&T`, and the plain call `f(x)` auto-borrows — x is NOT
// consumed, so it remains usable after the call, in loops, across
// conditionals, and after break. (Formerly pinned via the superseded D5
// share-place inference; the usable-after behavior now flows from the
// declared borrowing signatures.) Replaces the obsolete
// err_use_after_byvalue_*, err_*_carried_move,
// err_*_conditional_reinit_hides_move, err_*_move_then_break_use negatives.
// Systematic drop-count coverage lives in the /drop-audit skill.

type R { id: i32 }
impl Drop for R:
    fn drop(move self: Self): ()

fn take(r: &R): ()                // borrows by signature
fn read(r: &R) -> i32: r.id       // borrows by signature
fn make(n: i32) -> R: R { id: n }

fn after_byvalue_call() -> i32:
    let r = make(1)
    let n = read(r)               // auto-borrow
    n + r.id                       // r still usable → 1 + 1

fn carried_across_loop() -> i32:
    let r = make(10)
    for i in 0..3:
        take(r)                   // borrow each iteration; r not consumed
    r.id                           // still usable → 10

fn borrow_then_break() -> i32:
    let r = make(100)
    loop:
        take(r)
        break
    r.id                           // usable after break → 100

fn conditional_borrow(d: bool) -> i32:
    var r = make(1000)
    if d:
        take(r)                   // borrow on one path
    else:
        r = make(2000)            // reinit on the other
    r.id                           // usable on both paths

fn main:
    assert(after_byvalue_call() == 2)
    assert(carried_across_loop() == 10)
    assert(borrow_then_break() == 100)
    assert(conditional_borrow(true) == 1000)
    assert(conditional_borrow(false) == 2000)
    print("ok")
