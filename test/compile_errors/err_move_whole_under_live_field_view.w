//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// #1530 (§21.1 Rule 2): `move x` while a view of `x.s` is live is refused;
// the moved value's drop freed the string under the view.
type S { s: str, n: i32 }
fn take(s: S) -> i32: s.n
fn main:
    var x = S { s: "x" ++ "y", n: 1 }
    let p = x.s
    let q = take(move x)
    print(p)
    print(f"{q}")
