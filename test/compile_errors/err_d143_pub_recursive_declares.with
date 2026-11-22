//! expect-check-fail: a `pub fn` declares its return type (Law 6); write `->` (D143)
// D143 / Law 6: the inference is for package-local functions; a `pub fn`
// that calls itself declares its return type.
pub fn fact(n: i32):
    if n <= 1: 1 else: n * fact(n - 1)
fn main:
    print(f"{fact(4)}")
