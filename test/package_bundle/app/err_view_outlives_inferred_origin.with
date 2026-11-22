//! expect-error: returned view may outlive its origin 'local'

// #3401: the two inferred origins of bigger are both checked.
use shapes
fn pick(a: &Shape) -> &Shape:
    let local = Shape { w: 9, h: 9, name: "local" }
    bigger(a, local)
fn main:
    let a = Shape { w: 2, h: 3, name: "a" }
    print(pick(a).name)
