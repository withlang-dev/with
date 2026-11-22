type Point { x: i32, y: i32 }

fn check(p: Point, ex: i32, ey: i32):
    assert(p.x == ex)
    assert(p.y == ey)

fn main:
    let p1 = Point { 10, 20 }
    check(p1, 10, 20)

    let p2 = Point { 3 + 4, 5 * 6 }
    check(p2, 7, 30)

    // trailing comma
    let p3 = Point { 1, 2, }
    check(p3, 1, 2)
