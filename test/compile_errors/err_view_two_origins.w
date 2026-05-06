//! expect-check-fail: may outlive its origin

type Box { n: i32 }

fn longest(a: &Box, b: &Box, prefer_a: bool) -> &Box:
    if prefer_a:
        return a
    return b

fn leak(a: &Box) -> &Box:
    let b = Box { n: 2 }
    return longest(a, &b, false)

fn main:
    let a = Box { n: 1 }
    let view = leak(&a)
    assert(view.n == 2)
