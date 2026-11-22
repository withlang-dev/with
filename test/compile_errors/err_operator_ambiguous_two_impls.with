//! expect-check-fail: ambiguous operator '=='

// §11.7 (#2611, D166): == may dispatch from either side, so when both
// operand types provide distinct applicable eq implementations the
// expression is ambiguous. (For every other operator each side's
// implementation serves only its own order and there is no ambiguity:
// Left.add(Right) and Right.add(Left) coexist.)

type Left { value: i32 }
type Right { value: i32 }

impl Left:
    fn eq(self: &Self, rhs: Right) -> bool:
        self.value == rhs.value
    fn add(self: &Self, rhs: Right) -> i32:
        self.value + rhs.value

impl Right:
    fn eq(self: &Self, lhs: Left) -> bool:
        lhs.value == self.value
    fn add(self: &Self, lhs: Left) -> i32:
        lhs.value + self.value

fn main:
    let _ = Left { value: 1 } + Right { value: 2 }
    let _ = Left { value: 1 } == Right { value: 2 }
