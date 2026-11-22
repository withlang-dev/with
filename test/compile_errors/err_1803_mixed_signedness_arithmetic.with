//! expect-error: arithmetic on `i32` and `u32` needs an explicit `as` on one operand

// §4.2.6: an arithmetic operator's operands convert to one type only by a
// lossless widening; i32 and u32 widen into neither. The sum took the left
// operand's type and wrapped the unsigned one silently.
fn main:
    let a: i32 = -1
    let b: u32 = 3000000000
    print(f"{a + b}")
