//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// #1530 (§2.2 D32, §21.1 Rules 1-2): an explicit `move x.s` vacates the
// field — a write — so it is refused while a view of `x.s` is live, exactly
// as the assignment `x.s = ...` is. The view read the blank otherwise.
type S { s: str, n: i32 }
fn main:
    var x = S { s: "x" ++ "y", n: 1 }
    let p = x.s
    let q = move x.s
    print(p)
    print(q)
