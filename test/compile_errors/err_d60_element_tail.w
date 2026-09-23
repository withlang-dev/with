//! expect-check-fail: cannot move out of element `v[0]`

// §9.1 / D60 with D27: an element is observed, never moved out of its
// collection; the tail assignment's read of `v[0]` would move a str out.

fn f -> str:
    var v: Vec[str] = Vec.new()
    v.push("a".clone())
    v[0] = "b".clone()

fn main: print(f())
