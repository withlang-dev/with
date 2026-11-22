//! expect-exit: 0

// D27 E1: IndexPlace writes through the physical element place.

fn main:
    var xs: List[i32] = List.new()
    xs.push(1)
    xs[0] = 5
    assert(xs[0] == 5)
