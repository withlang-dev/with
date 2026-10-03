//! expect-check-fail: call to `bump` mutates global `HIDDEN` while `r` is a live view into it

// #1903 (§21.1 rule 6): a method that returns a view of a global, not of
// its receiver. `r` views HIDDEN, not `p`, and `bump` writes HIDDEN.

type Pair { a: i32, b: i32 }

var HIDDEN = Pair { a: 1, b: 2 }

fn bump(): HIDDEN = Pair { a: 3, b: 4 }

impl Pair:
    fn hidden() -> &Pair: &HIDDEN

fn main:
    let p = Pair { a: 0, b: 0 }
    let r = p.hidden()
    bump()
    print(r.a)
