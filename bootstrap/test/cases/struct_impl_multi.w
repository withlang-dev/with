// Test: structs with multiple impl methods

type Vec2 = { x: i32, y: i32 }

impl Vec2
    fn new(x: i32, y: i32) -> Vec2: Vec2 { x: x, y: y }

    fn add(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }

    fn scale(self: Vec2, factor: i32) -> Vec2:
        Vec2 { x: self.x * factor, y: self.y * factor }

    fn dot(self: Vec2, other: Vec2) -> i32:
        self.x * other.x + self.y * other.y

    fn mag_sq(self: Vec2) -> i32:
        self.x * self.x + self.y * self.y

fn main -> i32:
    let a = Vec2.new(3, 4)
    let b = Vec2.new(1, 2)

    let c = Vec2.add(a, b)
    println(c.x)
    println(c.y)

    let d = Vec2.scale(a, 3)
    println(d.x)
    println(d.y)

    let dot = Vec2.dot(a, b)
    println(dot)

    let mag = Vec2.mag_sq(a)
    println(mag)

