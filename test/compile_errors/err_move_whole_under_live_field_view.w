//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// #1530 (§21.1 Rule 2): `move x` while a view of `x.s` is live is refused;
// the moved value's drop freed the value under the view. The field is a
// List: a str field's binding takes the str (#3026, D179) and views nothing.
type S { s: List[i32], n: i32 }
fn take(s: S) -> i32: s.n
fn main:
    var x = S { s: [1, 2], n: 1 }
    let p = x.s
    let q = take(move x)
    print(p.len())
    print(f"{q}")
