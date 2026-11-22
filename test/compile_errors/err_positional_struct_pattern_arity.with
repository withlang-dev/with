//! expect-error: struct pattern 'Point' expects 2 field pattern(s), found 1

type Point {
    x: i32,
    y: i32,
}

fn main:
    let p = Point { x: 1, y: 2 }
    match p:
        Point(x) => assert(x == 1)
        _ => assert(false)
