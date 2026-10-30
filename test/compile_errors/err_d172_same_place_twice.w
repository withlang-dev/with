//! expect-error: `xs` is passed to a `mut` parameter and to another parameter of the same call (§3.2)
// D172 (2), §3.2: a `mut` parameter is exclusive for the call; the same
// place may not reach a second parameter of either mode.
fn both(mut a: List[i32], mut b: List[i32]):
    a.push(1)
    b.push(2)

fn main:
    var xs: List[i32] = []
    both(xs, xs)
    print(xs.len())
