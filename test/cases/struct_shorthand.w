type Vec2 = { x: i32, y: i32, z: i32 = 0 }

fn main -> i32:
    let x: i32 = 20
    let y: i32 = 22
    let v: Vec2 = Vec2 { x, y }
    assert(v.x + v.y + v.z == 42)
