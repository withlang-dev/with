// Test: string interpolation with variables and field access

type Point = { x: i32, y: i32 }

fn main -> i32:
    let x = 42
    let name = "world"
    println("hello {name}")
    println("x = {x}")

    let p = Point { x: 10, y: 20 }
    println("point = ({p.x}, {p.y})")
