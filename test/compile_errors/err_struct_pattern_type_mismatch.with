//! expect-check-fail: struct pattern 'Other' does not match subject type 'Point'

// #1388: a named struct pattern names the subject's own type.

type Point { x: i32, y: i32 }
type Other { x: i32 }

fn f(p: Point) -> i32:
    match p:
        Other { x } => x
        _ => 0

fn main:
    print(f(Point { x: 1, y: 2 }))
