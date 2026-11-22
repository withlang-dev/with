//! expect-error: `xs` is passed to a `mut` parameter and to another parameter of the same call (§3.2)
// D172 (2), §3.2: a `mut` parameter excludes even a read of the same place
// in the same call.
fn grow_by(mut a: List[i32], b: &List[i32]):
    for v in b: a.push(v)

fn main:
    var xs: List[i32] = [1]
    grow_by(xs, xs)
    print(xs.len())
