//! expect-check-fail: cannot mutate `s` while `t` is a live view into it
// §9.1 / D73 with §21.1 Rule 1 (#1479): `let t = (s = e)` binds a view of
// `s`; writing `s` while `t` is live is refused.
fn compute(s: &str): s.clone() ++ "!"
fn main:
    var s = "".clone()
    let t = (s = compute("x"))
    s = compute("y")
    print(t)
