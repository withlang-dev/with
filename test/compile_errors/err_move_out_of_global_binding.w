//! expect-check-fail: cannot move out of global `g`

// #1242: a global always holds a value and has no drop flag. Moving it into a
// local left the old bytes in the global: the reassignment dropped them, and
// so did the caller of the returned value (debug-alloc: DOUBLE FREE).

var g: Vec[str] = Vec.new()

fn take() -> Vec[str]:
    let out = g
    g = Vec.new()
    out

fn main:
    g.push("a")
    let t = take()
    print(f"{t.len()}")
