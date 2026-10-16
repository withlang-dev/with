//! expect-error: `??` would need to copy a `List[Tok]`, which is not Copy

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn main:
    let found: List[Tok] = List.new()
    let fallback: List[Tok] = List.new()
    let carrier: Option[&List[Tok]] = Some(&found)
    let owned = carrier ?? fallback
