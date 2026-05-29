//! expect-check-fail: field 'data' is not Copy

type CopySafetyBuffer { data: Vec[u8] }
impl Copy for CopySafetyBuffer
