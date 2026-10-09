//! expect-check-fail: cannot move out of element `v[0]`

// §9.1 / D60 with D27: an element is observed, never moved out of its
// collection; the tail assignment's read of `v[0]` would move a List out.
// A List element, not a str: a str element is copied (D111).

fn f -> List[i32]:
    var v: List[List[i32]] = List.new()
    v.push([1])
    v[0] = [2]

fn main: print(f().len())
