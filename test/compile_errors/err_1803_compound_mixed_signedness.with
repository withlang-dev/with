//! expect-error: arithmetic on `u32` and `i32` needs an explicit `as` on one operand

// §4.2.6: `x += s` is `x = x + s`, under the same operand rule. The u32
// accumulator took the i32 silently.
fn main:
    let s: i32 = -2
    var x: u32 = 10
    x += s
    print(f"{x}")
