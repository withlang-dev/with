//! expect-check-fail: return type mismatch

// §4.5 (D75, #1802): a cast through a reference borrows and yields a view —
// `r as List[Tok]` with `r: &Items` is a `&List[Tok]`, never an owned value
// (that would be a second owner of the caller's buffer). An owned result is
// spelled `(r as List[Tok]).clone()`. A distinct List, not a distinct str: a
// str view meets an owned demand with a copy (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Items = distinct List[Tok]

fn owned(r: &Items) -> List[Tok]: r as List[Tok]

fn main:
    let v: List[Tok] = [Tok { id: 1 }, Tok { id: 2 }]
    let n = v as Items
    print(owned(n).len())
