// Test: compound assignment with operator overloading
type Vec2 = { x: i32, y: i32 }

impl Vec2 =
    fn add(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }

    fn sub(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x - other.x, y: self.y - other.y }

    fn mul(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x * other.x, y: self.y * other.y }

fn main -> i32:
    var v = Vec2 { x: 1, y: 2 }
    let d = Vec2 { x: 3, y: 4 }
    v += d
    assert(v.x == 4)
    assert(v.y == 6)
    v -= Vec2 { x: 1, y: 1 }
    assert(v.x == 3)
    assert(v.y == 5)
    v *= Vec2 { x: 2, y: 3 }
    assert(v.x == 6)
    assert(v.y == 15)
