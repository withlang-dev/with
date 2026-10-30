//! expect-error: a `mut` parameter needs a mutable place: `xs` is a `let` binding (§3.8a)
// D172 (2), §3.8a: the argument of a `mut` parameter is a mutable place;
// a `let` binding is not one.
fn add(mut xs: List[i32]): xs.push(1)

fn main:
    let xs: List[i32] = []
    add(xs)
    print(xs.len())
