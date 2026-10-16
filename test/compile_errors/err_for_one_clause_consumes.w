//! expect-error: use of moved value

// §13.6a: a one-clause comprehension consumes its clause like the match it
// is equivalent to; the Option is gone afterwards. A List payload, not a
// str: an Option[str] is a value and is copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn main:
    let o: Option[List[Tok]] = Some([Tok { id: 1 }, Tok { id: 2 }])
    for x in o:
        print(x.len())
    print(f"{o.is_some()}")
