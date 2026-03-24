//! expect-stdout: ok

type Vec2 { x: i32, y: i32 }

fn Vec2.add(self: Vec2, other: Vec2) -> Vec2:
    Vec2 { x: self.x + other.x, y: self.y + other.y }

fn Vec2.sub(self: Vec2, other: Vec2) -> Vec2:
    Vec2 { x: self.x - other.x, y: self.y - other.y }

fn Vec2.eq(self: Vec2, other: Vec2) -> bool:
    self.x == other.x and self.y == other.y

fn main:
    let a = Vec2 { x: 1, y: 2 }
    let b = Vec2 { x: 3, y: 4 }
    let c = a + b
    assert(c.x == 4)
    assert(c.y == 6)

    let d = b - a
    assert(d.x == 2)
    assert(d.y == 2)

    let e = Vec2 { x: 4, y: 6 }
    assert(c == e)

    println("ok")
