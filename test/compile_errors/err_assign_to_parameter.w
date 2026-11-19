//! expect-check-fail: cannot assign to the parameter `x`: a parameter is an immutable binding (§9)
//! expect-check-fail: = help: for a local copy write `var x = x` before this line; to change the caller's variable declare the parameter `mut x`

// D220 (#690).
fn bump(x: i32) -> i32:
    x = x + 1
    x

fn main:
    print(bump(1))
