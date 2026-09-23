//! expect-error: let ... else requires an else branch for refutable patterns

// A qualified variant pattern is refutable in a let as in a match arm (#1373).
enum Shape:
    Named(i32)
    Empty

fn g(s: Shape) -> i32:
    let Shape.Named(n) = s
    n

fn main:
    print(f"{g(Shape.Named(3))}")
