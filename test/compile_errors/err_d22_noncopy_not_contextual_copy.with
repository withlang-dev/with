//! expect-error: type mismatch in binding

// A transparent carrier preserves the exact &List payload. Context cannot copy
// a non-Copy pointee into an owned List.
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn main:
    let values: List[Tok] = List.new()
    let carrier: Option[&List[Tok]] = Some(&values)
    let view = carrier.unwrap()
    let owned: List[Tok] = view
