//! expect-check-fail: must match the trait

// D140: an impl method's written parameter type must match the trait's
// declaration, instantiated for the impl.
pub trait Scale:
    fn scale(self: &Self, k: i32) -> i32

type P { v: i32 }

impl Scale for P: fn scale(k: i64) -> i32: self.v * k as i32

fn main:
    print(f"{P { v: 6 }.scale(7)}")
