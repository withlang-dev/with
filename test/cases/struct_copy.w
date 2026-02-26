type Point = { x: i32, y: i32 }

fn main() -> i32 =
    let p1 = Point { x: 1, y: 2 }
    let p2 = { p1 with x: 10 }
    println(p2.x)
    println(p2.y)
    let p3 = { p2 with y: 20 }
    println(p3.x)
    println(p3.y)
    0
