//! expect-check-fail: a `c_char` is not a `u8`: the conversion is written, and keeps the byte (§16.1)
//! expect-check-fail: = help: write `… as u8`

// D207 (§16.1, #3375): a value conversion between `c_char` and `u8` is written; the implicit one carried a range check on a signed-`char` target and none on an unsigned one. The same
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
    let b: u8 = c
    print(b)
