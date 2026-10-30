//! expect-error: a `mut` parameter needs a mutable place: the argument is a temporary (§3.8a)
// D172 (2), §3.8a: a temporary is no place the caller keeps.
fn add(mut xs: List[i32]): xs.push(1)

fn make() -> List[i32]: []

fn main:
    add(make())
