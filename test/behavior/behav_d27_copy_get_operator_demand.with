//! expect-exit: 0

// D27 E1: `xs.get(0)` is `&i32`; operator position materializes.

fn main:
    var xs: List[i32] = List.new()
    xs.push(41)
    assert(xs[0] + 1 == 42)
