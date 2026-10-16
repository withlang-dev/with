//! expect-check-fail: field 'data' is not Copy

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type CopySafetyBuffer { data: List[Tok] }
impl Copy for CopySafetyBuffer
