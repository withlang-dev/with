//! expect-check-fail: cannot move out of element `v[0]`

// §9.1 / D60 with D27: an element is observed, never moved out of its
// collection; the tail assignment's read of `v[0]` would move a Vec out.
// A Vec element, not a str: a str element is copied (D111).

fn f -> Vec[i32]:
    var v: Vec[Vec[i32]] = Vec.new()
    v.push([1])
    v[0] = [2]

fn main: print(f().len())
