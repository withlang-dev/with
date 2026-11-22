//! expect-exit: 0

// D27 E1: the by-value i32 parameter demands an owned value, so contextual
// Copy materializes the element view.

fn add_one(n: i32) -> i32: n + 1

fn main:
    var xs: List[i32] = List.new()
    xs.push(6)
    assert(add_one(xs[0]) == 7)
