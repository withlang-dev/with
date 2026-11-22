//! expect-error: closure argument holds `xs` by place

// #3401: later returns a closure that holds its parameter, which nothing declares.
use shapes
fn main:
    var xs: List[i32] = [1]
    let g = later(() => xs.len32())
    print(g())
