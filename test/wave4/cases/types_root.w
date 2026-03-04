// Cross-module type and enum declarations.
use types.defs

fn describe(s: Shape) -> i32:
    match s
        Circle(r) -> r
        Rect(w) -> w

fn main -> i32:
    let c = Circle(5)
    describe(c)
