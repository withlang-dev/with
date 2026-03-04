type Point = { x: i32, y: i32 }

fn sum_ref(p: &Point) -> i32:
    p.x + p.y

fn main -> i32:
    let p = Point { x: 2, y: 5 }
    if sum_ref(p) == 7 then 0 else 1
