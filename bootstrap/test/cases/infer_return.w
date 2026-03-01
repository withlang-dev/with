//! run
//! expect: 3, 4
//! expect: hello
//! expect: 42

type Vec2 = { x: f64, y: f64 }

fn origin: Vec2 { x: 3.0, y: 4.0 }

fn get_name: "hello"

fn get_count: 42

fn main:
    let v = origin()
    println("{v.x}, {v.y}")
    let n = get_name()
    println(n)
    let c = get_count()
    println("{c}")
