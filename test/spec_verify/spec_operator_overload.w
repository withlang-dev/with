// POSITIVE: operator overloading — a + b dispatches to .add() (§11.7)
type Vec2 = { x: i32, y: i32 }

impl Vec2 =
    fn add(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }

    fn eq(self: Vec2, other: Vec2) -> bool:
        self.x == other.x and self.y == other.y

fn main -> i32:
    let a = Vec2 { x: 1, y: 2 }
    let b = Vec2 { x: 3, y: 4 }
    let c = a + b
    assert(c.x == 4)
    assert(c.y == 6)
    println("operator overload ok")
