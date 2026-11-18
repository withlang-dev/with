//! expect-check-fail: a `c_char` does not widen into the unsigned `u32`: its sign is the target's `char` (§16.1)
//! expect-check-fail: = help: write `… as u32`, or widen into a signed type

// D207 (§16.1, #3375): only a wider signed type keeps a `c_char`'s value on every target. The same
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
    let w: u32 = c
    print(w)
