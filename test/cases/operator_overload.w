// Test: Operator overloading via syntax traits
type Vec2 = { x: i32, y: i32 }

impl Vec2
    fn add(self: Vec2, other: Vec2) -> Vec2 =
        Vec2 { x: self.x + other.x, y: self.y + other.y }

    fn sub(self: Vec2, other: Vec2) -> Vec2 =
        Vec2 { x: self.x - other.x, y: self.y - other.y }

    fn eq(self: Vec2, other: Vec2) -> bool =
        self.x == other.x and self.y == other.y

    fn mul(self: Vec2, other: Vec2) -> Vec2 =
        Vec2 { x: self.x * other.x, y: self.y * other.y }

fn main() -> i32 =
    let a = Vec2 { x: 1, y: 2 }
    let b = Vec2 { x: 3, y: 4 }

    // + operator calls Vec2.add
    let c = a + b
    assert(c.x == 4)
    assert(c.y == 6)

    // - operator calls Vec2.sub
    let d = b - a
    assert(d.x == 2)
    assert(d.y == 2)

    // == operator calls Vec2.eq
    let e = Vec2 { x: 1, y: 2 }
    assert(a == e)

    // * operator calls Vec2.mul
    let f = a * b
    assert(f.x == 3)
    assert(f.y == 8)

    println("all operator overload tests passed")
    0
