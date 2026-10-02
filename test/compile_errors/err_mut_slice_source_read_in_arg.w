//! expect-check-fail: cannot be read here while the callee is writing into it

// #604 §21.1 call-local exclusivity: while a call writes through a []mut view
// of v, another argument of the same call may not read v.

fn fill(buf: []mut i32, n: i32): ()

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(1)
    fill(v, v[0])
