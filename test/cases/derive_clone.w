// Test @[derive(Clone)] generates clone method

@[derive(Clone)]
type Point = {
    x: i32,
    y: i32,
}

fn main() -> i32 =
    let p = Point { x: 10, y: 20 }
    let q = p.clone()
    assert(q.x == 10)
    assert(q.y == 20)
    0
