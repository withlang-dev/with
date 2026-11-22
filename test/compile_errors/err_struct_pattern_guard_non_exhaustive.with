//! expect-check-fail: non-exhaustive match on 'Point': `Point { x: 1, .. }` is not covered

// #1388 (§9.7): a guarded arm covers nothing for exhaustiveness; the
// unguarded `Point { x: 0, .. }` leaves every other x uncovered.

type Point { x: i32, y: i32 }

fn f(p: Point) -> i32:
    match p:
        Point { x, y } if x > 0 => y
        Point { x: 0, .. } => 0

fn main:
    print(f(Point { x: 1, y: 2 }))
