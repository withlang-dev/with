// Test: derive Clone with .clone() method
@[derive(all)]
type Point = { x: i32, y: i32 }

fn main() -> i32 =
    let p = Point { x: 10, y: 32 }
    let q = p.clone()
    if q.x + q.y == 42 then 0 else 1
