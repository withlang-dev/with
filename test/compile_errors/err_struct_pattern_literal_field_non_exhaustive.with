//! expect-check-fail: non-exhaustive match on 'Point': `Point { x: 1, .. }` is not covered

// #1388 (§9.7): `Point { x: 0, y }` covers only the points whose x is 0.
// An expression-position match must cover every Point.

type Point { x: i32, y: i32 }

fn f(p: Point) -> i32:
    match p:
        Point { x: 0, y } => y

fn main:
    print(f(Point { x: 1, y: 2 }))
