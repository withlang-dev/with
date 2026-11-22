//! expect-stdout: true false 8 -3
// #2611 (§11.7): ==/!= dispatch from either side (Eq is symmetric by
// contract); every other operator uses only the implementation whose
// Self is the left operand, and two types may each define their own
// order without ambiguity.
type V { x: f64 }

impl V:
    fn eq(self: &Self, rhs: f64) -> bool:
        self.x == rhs
    fn sub(self: &Self, rhs: f64) -> V:
        V { x: self.x - rhs }

type W { n: i32 }

impl W:
    fn sub(self: &Self, rhs: V) -> i32:
        self.n - rhs.x as i32

fn main:
    let a = V { x: 10.0 }
    let b = a - 2.0
    let w = W { n: 7 }
    print(f"{10.0 == a} {10.0 != a} {b.x as i32} {w - a}")
