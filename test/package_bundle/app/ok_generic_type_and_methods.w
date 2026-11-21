//! expect: ok

// #3401: a generic type, its methods, and a generic method of a plain type.
use shapes
fn main:
    let p = Pair { a: 1, b: 2 }
    print(p.first())
    print(p.swapped().a)
    let t = Tally { n: 5 }
    print(t.plus_count(["x", "y"]))
