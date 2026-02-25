// Test: Struct methods via impl blocks
type Vec2 = { x: i32, y: i32 }

impl Vec2 =
    fn new(x: i32, y: i32) -> Vec2 =
        Vec2 { x, y }

    fn magnitude_sq(self: Vec2) -> i32 =
        self.x * self.x + self.y * self.y

    fn add(self: Vec2, other: Vec2) -> Vec2 =
        Vec2 { x: self.x + other.x, y: self.y + other.y }

fn main() -> i32 =
    let a = Vec2.new(3, 4)
    let b = Vec2.new(1, 2)
    let c = a.add(b)
    assert(a.magnitude_sq() == 25)
    assert(c.x == 4)
    assert(c.y == 6)
    0
