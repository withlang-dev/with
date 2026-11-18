//! expect-check-fail: a `i32` converts to `c_char` only with `as`: which values fit depends on the target's `char` (§16.1)
//! expect-check-fail: = help: write `… as c_char`

// D207 (§16.1, #3375): a wider integer does not narrow into `c_char` with a range check: the range is the target's. The same
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
    let k: c_char = wide
    print(k)
