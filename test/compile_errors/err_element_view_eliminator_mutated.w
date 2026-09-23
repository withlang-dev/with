//! expect-check-fail: cannot mutate `v` while `x` is a live view into it

// #1406 (§3.8, D22): `??` and `unwrap_or` are eliminators; the element view
// on the fallback side keeps its origin `v`.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v

fn g(o: Option[&str]):
    var v = mkv()
    let x = o ?? v[0]
    for i in 0..100:
        v.push("q".clone())
    print(x)

fn main:
    g(None)
