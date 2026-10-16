//! expect-check-fail: cannot move out of element `v[0]`

// §9.1 / D60 with D27: an element is observed, never moved out of its
// collection; the tail assignment's read of `v[0]` would move a List out.
// A List element, not a str: a str element is copied (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn f -> List[Tok]:
    var v: List[List[Tok]] = List.new()
    v.push([Tok { id: 1 }])
    v[0] = [Tok { id: 2 }]

fn main: print(f().len())
