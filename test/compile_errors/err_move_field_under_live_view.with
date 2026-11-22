//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// #1530 (§2.2 D32, §21.1 Rules 1-2): an explicit `move x.s` vacates the
// field — a write — so it is refused while a view of `x.s` is live, exactly
// as the assignment `x.s = ...` is. The view read the blank otherwise. The
// field is a List: a str field's binding takes the str (#3026, D179) and
// views nothing.
type S { s: List[i32], n: i32 }
fn main:
    var x = S { s: [1, 2], n: 1 }
    let p = x.s
    let q = move x.s
    print(p.len())
    print(q.len())
