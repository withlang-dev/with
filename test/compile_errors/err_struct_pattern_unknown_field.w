//! expect-check-fail: struct pattern names no field 'z' of 'Point'

// #1388: a struct pattern field must be a field of the subject.

type Point { x: i32, y: i32 }

fn f(p: Point) -> i32:
    match p:
        Point { z: 0, .. } => 1
        _ => 0

fn main:
    print(f(Point { x: 1, y: 2 }))
