//! expect-check-fail: use of moved value

// #782 arm 2 / D144: `let (a, b) = move t` takes the tuple apart (MIR moves
// every element), so a later projection reads blanked storage and must be
// rejected. Without `move` the let observes `t` (D144) and `t.1` stays
// readable. A List element, not a str: a str is a value and is copied (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn pair() -> (i32, List[Tok]): (42, [Tok { id: 1 }, Tok { id: 2 }])

fn main:
    let t = pair()
    let (a, b) = move t
    print(t.1.len())
    let _ = a
    print(b.len())
