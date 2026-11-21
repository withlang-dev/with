//! expect-error: wrong argument type in call to 'widest'

// #3401: a generic function's parameters are checked at the importer's call.
use shapes
fn main:
    let xs = [Shape { w: 2, h: 3, name: "a" }]
    print(widest(xs, 5))
