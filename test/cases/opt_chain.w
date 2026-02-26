// Test optional chaining (?.)

type Point = { x: i32, y: i32 }

fn get_point(flag: bool) -> ?Point:
    if flag then Some(Point { x: 10, y: 20 }) else None

fn main -> i32:
    let p1 = get_point(true)
    let x1 = p1?.x ?? 0
    assert(x1 == 10)

    let p2 = get_point(false)
    let x2 = p2?.x ?? 0
    assert(x2 == 0)
