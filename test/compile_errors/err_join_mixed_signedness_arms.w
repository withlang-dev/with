//! expect-error: if arms have types `i32` and `u32`; no implicit conversion joins them (§4.2.6), so spell one arm with `as`

// §4.2.6: two typed numeric arms meet where an operator's operands meet, at
// the type one widens into losslessly; i32 and u32 widen into neither. The
// join took the left arm at equal width, and the u32 arm changed sign.
fn main:
    let a: i32 = -1
    let b: u32 = 3000000000
    let c = a < 0
    let joined = if c: a else: b
    print(f"{joined}")
