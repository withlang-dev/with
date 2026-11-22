//! expect-exit: 134
//! expect-stderr: integer does not fit `u32`
// §4.2.6 (D183): a negative value where an unsigned integer is demanded
// is out of range; the check fires before the store.
fn main:
    let x: i32 = -1
    let u: u32 = x
    print(u)
