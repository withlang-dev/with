//! expect-check-fail: ambiguous operator '+'

type Left { value: i32 }
type Right { value: i32 }

impl Left:
    fn add(self: &Self, rhs: Right) -> i32:
        self.value + rhs.value

impl Right:
    fn add(self: &Self, lhs: Left) -> i32:
        lhs.value + self.value

fn main:
    let _ = Left { value: 1 } + Right { value: 2 }
