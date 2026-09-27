//! expect-check-fail: cannot mutate `s` while `t` is a live view into it
// §9.1 / D73 with §21.1 Rule 1 (#1479): the view an assignment-arm join
// binds keeps `s` from being written while it is live.
fn compute(s: &str): s.clone() ++ "!"
fn main:
    var s = "".clone()
    let p = s.len() == 0
    let t = if p: s = compute("y") else: s = compute("n")
    s = compute("z")
    print(t)
