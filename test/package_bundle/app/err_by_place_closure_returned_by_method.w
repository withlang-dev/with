//! expect-error: closure argument holds `xs` by place

// #3401: a method that returns a closure holding its parameter, which nothing declares.
use shapes
fn main:
    let k = Keeper { held: [] }
    var xs: List[i32] = [1]
    let g = k.wrapped(() => xs.len32())
    print(g())
