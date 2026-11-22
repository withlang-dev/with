//! expect-exit: 134
//! expect-stderr: integer does not fit `u32`
// D197 (§4.2.4): a signed shift count converts to `u32` with a range check,
// as a D183 narrowing does; a negative count panics instead of shifting by
// a huge unsigned amount.
fn count(n: i32) -> i32: n - 5

fn main:
    let c = count(2)
    print(f"{1 << c}")
