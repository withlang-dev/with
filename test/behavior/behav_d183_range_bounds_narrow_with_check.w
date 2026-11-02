//! expect-stdout: 1
//! expect-stdout: 2
// §4.2.6 (D183): a range whose bounds have no lossless join narrows the
// other bound to the first's type with a range check.
fn main:
    let a: i32 = 1
    let b: u32 = 3
    for i in a..b:
        print(f"{i}")
