//! expect-error: unknown method 'third'

// #3401: a generic type's methods are the ones its interface carries.
use shapes
fn main:
    let p = Pair { a: 1, b: 2 }
    print(p.third())
