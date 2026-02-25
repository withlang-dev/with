type Point = { x: i32, y: i32 }

fn make_point(x: i32, y: i32) -> Point =
    Point { x: x, y: y }

fn main() -> i32 =
    let p: Point = make_point(20, 22)
    assert(p.x + p.y == 42)
    0
