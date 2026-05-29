//! expect-stdout: ok

type Vector { x: i32, y: i32 }
type Bias { amount: i32 }

impl Vector:
    fn add(self: &Self, rhs: &Self) -> Vector:
        Vector { x: self.x + rhs.x, y: self.y + rhs.y }

    fn sub(self: &Self, rhs: Bias) -> Vector:
        Vector { x: self.x - rhs.amount, y: self.y - rhs.amount }

impl Bias:
    fn add(self: &Self, lhs: Vector) -> Vector:
        Vector { x: lhs.x + self.amount, y: lhs.y + self.amount }

fn main:
    let a = Vector { x: 1, y: 2 }
    let b = Vector { x: 3, y: 4 }
    let sum = a + b
    assert(sum.x == 4)
    assert(sum.y == 6)

    let shifted = a - Bias { amount: 1 }
    assert(shifted.x == 0)
    assert(shifted.y == 1)

    let reverse = Bias { amount: 10 } + a
    assert(reverse.x == 11)
    assert(reverse.y == 12)

    let chained = a + b + sum
    assert(chained.x == 8)
    assert(chained.y == 12)
    print("ok")
