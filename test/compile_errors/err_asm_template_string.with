//! expect-check-fail: expected assembly template string
// §16: the asm template must be a string literal.
fn main:
    let r: i64 = unsafe { asm(123 : out("x0") -> i64) }
    print("x")
