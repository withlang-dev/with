//! expect-error: `??` would need to copy a `List[i32]`, which is not Copy

fn main:
    let found: List[i32] = List.new()
    let fallback: List[i32] = List.new()
    let carrier: Option[&List[i32]] = Some(&found)
    let owned = carrier ?? fallback
