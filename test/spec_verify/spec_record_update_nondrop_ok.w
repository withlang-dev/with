// POSITIVE: record update on non-Drop type should succeed (§4.3)
type Point = { x: i32, y: i32 }

fn main -> i32:
    let p = Point { x: 10, y: 20 }
    let q = { p with x: 32 }
    assert(q.x == 32)
    assert(q.y == 20)
    println("record update ok")
