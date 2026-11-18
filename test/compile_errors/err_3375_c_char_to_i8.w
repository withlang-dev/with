//! expect-check-fail: a `c_char` is not a `i8`: the conversion is written, and keeps the byte (§16.1)
//! expect-check-fail: = help: write `… as i8`

// D207 (§16.1, #3375): `c_char` is not `i8`, on a signed-`char` target either. The same
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
    let s: i8 = c
    print(s)
