//! expect-check-fail: a `u8` is not a `c_char`: the conversion is written, and keeps the byte (§16.1)
//! expect-check-fail: = help: write `… as c_char`

// D207 (§16.1, #3375): a byte becomes a `c_char` with `as`. The same
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
    let k: c_char = ub
    print(k)
