//! expect-stdout: ok

type Vec2 { x: i32, y: i32 }

impl Vec2:
    fn add(self: Vec2, rhs: Vec2) -> Vec2:
        Vec2 { x: self.x + rhs.x, y: self.y + rhs.y }

fn test_lhs_dispatch:
    let a = Vec2 { x: 1, y: 2 }
    let b = Vec2 { x: 3, y: 4 }
    let c = a + b
    assert(c.x == 4)
    assert(c.y == 6)

fn main:
    test_lhs_dispatch()
    print("ok")
