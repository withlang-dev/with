//! expect-error: cannot consume read-only view binding `observed`

// A List, not a str: `*source` of a `&str` copies the str (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn consume(value: List[Tok]): print(value.len())
fn observe(source: &List[Tok]):
    let observed = *source
    consume(observed)

fn main:
    let v: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }]
    observe(&v)
