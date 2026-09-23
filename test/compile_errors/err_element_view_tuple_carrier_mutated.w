//! expect-check-fail: cannot mutate `v` while `t` is a live view into it

// #1406 (§3.4, §21.1 rule 10): a tuple of element views is a carrier of those
// views; construction preserves their origin `v`.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn main:
    var v = mkv()
    let t = (v[0], v[1])
    for i in 0..100:
        v.push("q".clone())
    print(t.0)
