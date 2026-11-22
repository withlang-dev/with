//! expect-check-fail: `200` is not a `c_char` literal: an integer literal from 0 to 127 is a `c_char` on every target (§16.1)
//! expect-check-fail: = help: write the value at an integer type and convert it: `… as c_char`

// D207 (§16.1, #3375): 200 is a `char` only where `char` is unsigned. The same
// refusal on every target.
fn takeu(p: *const u8) -> i32: 0

fn main:
    let p = c"hi".ptr
    let c: c_char = unsafe { *p }
    let ub: u8 = 1
    let sb: i8 = 1
    let wide: i32 = 7
    let uw: u32 = 7
    let xs: List[c_char] = []
    let k: c_char = 200
    print(k)
