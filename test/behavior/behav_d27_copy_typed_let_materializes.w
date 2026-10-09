//! expect-exit: 0

// D27 E1: the typed binding demands an owned i32, so contextual Copy
// materializes while the vec remains unaffected.

fn main:
    var xs: List[i32] = List.new()
    xs.push(7)
    let n: i32 = xs[0]
    assert(n == 7)
    assert(xs.len() == 1)
