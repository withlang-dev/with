// D39 emitter refusal fixture (§21.1 rules 1 and 6, #1903, D79): a global
// that is an origin of an exported function's returned view is part of the
// interface though private, so every exported function that writes it
// declares the write. `raise` writes LEVEL and declares nothing.
var LEVEL: i32 = 3
pub fn level() -> &i32 from LEVEL: &LEVEL
pub fn raise(): LEVEL = LEVEL + 1
