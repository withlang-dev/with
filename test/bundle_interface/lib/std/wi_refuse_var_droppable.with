// D39 emitter refusal fixture (#2369): a mutable global of a droppable type
// is refused, since nobody drops bundle storage. `TABLE` is only written
// into, so the refusal names the fix: spell it `let`.
pub var TABLE: List[i32] = [1, 2, 3]
pub fn set(i: i32, v: i32) writes TABLE: TABLE[i] = v
pub fn first() -> i32: TABLE[0]
