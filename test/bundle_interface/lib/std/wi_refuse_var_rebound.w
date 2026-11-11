// D39 emitter refusal fixture (#2369): `TABLE` is rebound by `reset`, so it
// cannot be a `let`, and the refusal names the rebinding site instead.
pub var TABLE: List[i32] = [1, 2, 3]
pub fn set(i: i32, v: i32) writes TABLE: TABLE[i] = v
pub fn reset() writes TABLE:
    TABLE = [4, 5, 6]
