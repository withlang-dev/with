//! expect-check-fail: equality between a `c_char` and a `u8` is refused: the result would differ by target (§16.1)
//! expect-check-fail: = help: convert one operand: `(c as u8)`, or `(x as c_char)`

// D207 (§16.1, #3375): equality between a `c_char` and a `u8` is refused like ordering. The same
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
    print(c == ub)
