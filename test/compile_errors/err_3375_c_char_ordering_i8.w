//! expect-check-fail: ordering between a `c_char` and a `i8` is refused: the result would differ by target (§16.1)
//! expect-check-fail: = help: convert one operand: `(c as i8)`, or `(x as c_char)`

// D207 (§16.1, #3375): the same two bytes order differently on a signed and an unsigned target. The same
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
    print(c < sb)
