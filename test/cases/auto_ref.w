// Test auto-referencing: passing owned values to &T parameters

type Point = {
    x: i32,
    y: i32,
}

fn print_point(p: &Point) -> i32 =
    p.x + p.y

fn add_points(a: &Point, b: &Point) -> i32 =
    a.x + b.x + a.y + b.y

fn main() -> i32 =
    let p = Point { x: 10, y: 20 }
    // Auto-ref: pass owned Point where &Point is expected
    let sum = print_point(p)
    assert(sum == 30)

    let q = Point { x: 5, y: 15 }
    let total = add_points(p, q)
    assert(total == 50)
    0
