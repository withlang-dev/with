//! expect-check-fail: shadowing is not allowed for 'x'

// D220 (§29.8): a view of the old binding keeps it live after the new
// declaration, so the initializer did not consume it.
fn f(x: i32) -> i32:
    let r = &x
    let x = x + 1
    x + *r

fn main:
    print(f(1))
