//! expect-error: cannot take ownership of a non-Copy value through a borrow

// A List, not a str: `*source` of a `&str` copies the str (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn observe(source: &List[Tok]):
    var observed = *source
    print(observed.len())

fn main:
    let v: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }]
    observe(&v)
