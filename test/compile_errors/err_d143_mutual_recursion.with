//! expect-check-fail: call each other and neither declares a return type; write `->` on one of them (D143)
// D143: mutual recursion with no written return type names the cycle.
fn even(n: i32):
    if n == 0: true else: odd(n - 1)
fn odd(n: i32):
    if n == 0: false else: even(n - 1)
fn main:
    print(f"{even(4)}")
