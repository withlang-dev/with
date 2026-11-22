//! expect-check-fail: wrong argument type in call to 'takeu'

// D207 (§16.1, #3375): a pointer to `c_char` is never a pointer to `u8`. The same
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
    print(takeu(p))
