//! expect-check-fail: cannot mutate `v` while `x` is a live view into it

// #1406: the join carries the union of its arms' origins (§3.8 rule 3). The
// parameter view `r` must not hide the element origin `v` of the other arm.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v

fn g(c: bool, r: &str):
    var v = mkv()
    let x = if c: v[0] else: r
    v.clear()
    print(x)

fn main:
    let s = "zz".clone()
    g(true, &s)
