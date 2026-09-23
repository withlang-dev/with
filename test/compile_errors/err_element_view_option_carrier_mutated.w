//! expect-check-fail: cannot mutate `v` while `o` is a live view into it

// #1406 (§3.4): Option is transparent to view origins — `Some(v[0])` carries
// the element view and its origin `v`, through the if join too.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v

fn g(c: bool):
    var v = mkv()
    let o = if c: Some(v[0]) else: None
    for i in 0..100:
        v.push("q".clone())
    print(o.unwrap())

fn main:
    g(true)
