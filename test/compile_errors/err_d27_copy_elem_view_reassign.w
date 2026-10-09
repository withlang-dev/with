//! expect-error: cannot assign an owned value to a reference-typed binding

// D27 E1: `off` binds the `&i32` view. Reassignment produces an owned i32,
// which cannot be stored into that reference-typed binding.

fn main:
    var xs: List[i32] = List.new()
    xs.push(50)
    var off = xs[0]
    off = off + 1
    assert(off == 51)
