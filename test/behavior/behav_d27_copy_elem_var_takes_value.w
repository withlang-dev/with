//! expect-stdout: ok
// D144: a `var` of plain bits bound from an element is the value (D27 E1
// had it bind the `&i32` view, so `off = off + 1` stored an owned i32 into
// a reference-typed binding and was refused). The list is unchanged.

fn main:
    var xs: List[i32] = List.new()
    xs.push(50)
    var off = xs[0]
    off = off + 1
    assert(off == 51 and xs[0] == 50)
    print("ok")
