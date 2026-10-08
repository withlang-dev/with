//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// §9.1 / D60 with D32: a field of a local struct, as the tail `h.items` is.
// A Vec field, not a str: a str field is copied (D111).

type Holder { n: i32, items: Vec[i32] }
fn f -> Vec[i32]:
    var h = Holder { n: 0, items: Vec.new() }
    h.items = [1]

fn main: print(f().len())
