//! expect-error: moved inside a loop

// #696 companion (true positive preserved): a Drop value moved on the path that
// reaches a `continue` — LIVE at loop entry, MOVED at the continue — IS a
// loop-carried use-after-move and must still be rejected. The fall-through path
// (i <= 0) never moves `d`, so the loop-end back-edge is clean; only the
// continue back-edge catches it. This pins that the #696 fix narrowed the check
// to the entry==LIVE case without disabling the diagnostic.

type D { id: i32 }
impl Drop for D:
    fn drop(move self: Self): ()

fn consume(d: D): ()

fn f(n: i32):
    var d = D { id: 1 }
    for i in 0..n:
        if i > 0:
            consume(move d)    // moved on the continue path (LIVE at loop entry)
            continue           // back-edge with `d` MOVED → loop-carried move

fn main:
    f(3)
    print("ok")
