//! expect-error: type mismatch in binding

// A transparent carrier preserves the exact &List payload. Context cannot copy
// a non-Copy pointee into an owned List.
fn main:
    let values: List[i32] = List.new()
    let carrier: Option[&List[i32]] = Some(&values)
    let view = carrier.unwrap()
    let owned: List[i32] = view
