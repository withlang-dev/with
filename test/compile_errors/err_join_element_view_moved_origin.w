//! expect-check-fail: view 'x' may outlive its origin 'v'

// #1406: moving the origin of a live joined element view.

fn mkv() -> Vec[str]:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v.push("b".clone())
    v

fn g(c: bool):
    let v = mkv()
    let x = if c: v[0] else: v[1]
    let w = v
    print(x)
    print(w.len())

fn main:
    g(true)
