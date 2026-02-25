type Point = { x: i32, y: i32 }

fn main() -> i32 =
    let p = Point { x: 10, y: 20 }
    let q = { p with x: 32 }
    assert(q.x + q.y - 10 == 42)
    0
