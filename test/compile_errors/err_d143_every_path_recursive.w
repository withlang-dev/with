//! expect-check-fail: every path returns a call of `bounce` itself; write `->` (D143)
// D143: a body whose every path is a call of the function has no type.
fn bounce(n: i32):
    if n > 0: bounce(n - 1) else: bounce(n + 1)
fn main:
    bounce(1)
