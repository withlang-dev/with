//! expect-stdout: x=10 y=20

fn main:
    let p = Point { x: 10, y: 20 }
    println("x=" ++ int_to_string(p.x) ++ " y=" ++ int_to_string(p.y))

type Point = { x: i32, y: i32 }
