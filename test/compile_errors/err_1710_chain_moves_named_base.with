//! expect-error: use of moved value
// #1710 (§10.3, D74 interim): `o?.a` takes the non-Copy field `a` out of
// the named base `o` by moving the whole Option into a temporary. Sema now
// records that move, so the second chain is "use of moved value" instead of
// a silent `Some()`. D22 stage 4 retypes a named-base chain as a view.
// A List field, not a str: a str field is copied (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type P { a: List[Tok], b: i32 }

fn main:
    let o: Option[P] = Some(P { a: [Tok { id: 1 }, Tok { id: 2 }, Tok { id: 3 }], b: 4 })
    let first = o?.a
    let second = o?.a
    print(f"{first.is_some()} {second.is_some()}")
