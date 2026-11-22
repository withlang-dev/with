//! expect-check-fail: struct pattern requires a struct subject, found 'Shape'

// #1388: variants take positional payload patterns (§30.6 ENUM_PAT); a
// braced pattern on an enum subject used to reach codegen untyped.

enum Shape:
    Circle(r: i32)
    Sq(s: i32)

fn f(s: Shape) -> i32:
    match s:
        Circle { r } => r
        _ => 0

fn main:
    print(f(Shape.Circle(1)))
