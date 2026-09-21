//! expect-check-fail: cannot move out of global `g`

// #1242: a consuming parameter and a `move self` receiver take the global's
// value the same way a binding does.

var g: Vec[str] = Vec.new()

fn consume(v: Vec[str]) -> i64: v.len()

fn main:
    g.push("a")
    print(f"{consume(g)}")
