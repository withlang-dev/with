//! expect-error: positional struct pattern 'Point' requires subject type 'Point'

type Point {
    x: i32,
    y: i32,
}

type Other {
    x: i32,
    y: i32,
}

fn main:
    let other = Other { x: 1, y: 2 }
    match other:
        Point(x, y) => assert(x + y == 3)
        _ => assert(false)
