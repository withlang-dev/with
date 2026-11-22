//! expect-check-fail: operator '+' has no applicable implementation

type Vector { value: i32 }
type Matrix { value: i32 }

impl Vector:
    fn add(self: &Self, rhs: Matrix) -> Vector:
        Vector { value: self.value + rhs.value }

fn main:
    let _ = Vector { value: 1 } + Vector { value: 2 }
