//! expect-check-fail: non-exhaustive match on '&Point': `Point { x: 1, y: 1 }` is not covered

// #1388 (§9.7): a borrowed subject is matched through the reference; the
// two literal-field arms leave points with x and y both nonzero uncovered.

type Point { x: i32, y: i32 }

fn f(p: &Point) -> i32:
    match p:
        Point { x: 0, y } => y
        Point { x, y: 0 } => x

fn main:
    print(f(Point { x: 1, y: 2 }))
