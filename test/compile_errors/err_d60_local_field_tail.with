//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// §9.1 / D60 with D32: a field of a local struct, as the tail `h.items` is.
// A List field, not a str: a str field is copied (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Holder { n: i32, items: List[Tok] }
fn f -> List[Tok]:
    var h = Holder { n: 0, items: List.new() }
    h.items = [Tok { id: 1 }]

fn main: print(f().len())
