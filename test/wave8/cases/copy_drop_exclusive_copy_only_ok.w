@[derive(Copy)]
type Point = { x: i32, y: i32 }

fn main -> i32:
    let p1 = Point { x: 1, y: 2 }
    let p2 = p1
    if p1.x + p2.x == 2 then 0 else 1
