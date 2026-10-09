//! expect-exit: 0

// D27 E1: `n` binds `&i32`; the operator demand materializes an owned i32.
// The vec remains the owner; no element drop is introduced.

fn main:
    var xs: List[i32] = List.new()
    xs.push(7)
    let n = xs[0]
    assert(n + 1 == 8)
    assert(xs.len() == 1)
