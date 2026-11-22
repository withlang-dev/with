//! expect-exit: 0

// D27 E1: the annotation demands what it says. `var off: i32` materializes
// the Copy element; reassignment mutates independent scratch storage.

fn main:
    var xs: List[i32] = List.new()
    xs.push(50)
    var off: i32 = xs[0]
    off = off + 1
    assert(off == 51)
    xs.push(3)
    var pos: i32 = xs[1]
    pos = pos + 2
    assert(pos == 5)
