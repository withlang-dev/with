//! expect-check-fail: non-exhaustive match on '(Point, bool)': `(Point { x: 1, .. }, true)` is not covered

// #1388 (§9.7): a struct pattern nested in a tuple is tested field by field.

type Point { x: i32, y: i32 }

fn f(t: (Point, bool)) -> i32:
    match t:
        (Point { x: 0, .. }, true) => 1
        (_, false) => 2

fn main:
    print(f((Point { x: 0, y: 0 }, true)))
