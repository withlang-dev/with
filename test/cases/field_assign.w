type Point = { x: i32, y: i32 }

fn main() -> i32 =
    var p: Point = Point { x: 10, y: 20 }
    p.x = 22
    p.y = 20
    assert(p.x + p.y == 42)
    0
