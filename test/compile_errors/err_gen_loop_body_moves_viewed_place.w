//! expect-check-fail: cannot mutate `v` while `over(…)` is a live view into it

// D69 (§13.4, §21.1, #1734): moving the viewed place out in the body is refused like a
// write.
gen fn over(xs: &Vec[str]) -> &str:
    for x in xs:
        yield x

fn take(v: Vec[str]) -> i32: v.len() as i32

fn main:
    var v: Vec[str] = ["a".clone()]
    var n = 0
    for x in over(&v):
        n = take(move v)
        break
    print(n)
