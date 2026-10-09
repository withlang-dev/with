//! expect-check-fail: field 'data' is not Copy

type CopySafetyBuffer { data: List[u8] }
impl Copy for CopySafetyBuffer
