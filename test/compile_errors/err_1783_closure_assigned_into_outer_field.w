//! expect-check-fail: view `c` may originate from `n`, which no longer lives here

// #1783 / §12.4: a non-move closure is a view of `n`; assigning it into a
// field of the outer `c` stores that view where it outlives `n`. The snapshot
// is `move () => n`.
type Cnt { f: fn() -> i32 }
fn main:
    var c = Cnt { f: move () => 0 }
    for i in 0..3:
        let n = i * 10
        c.f = () => n
    print(c.f())
