//! expect-error: expected ':' or '{' to introduce body

fn helper() -> i32:
    42

fn main:
    let value = no_suspend helper()
    assert(value == 42)
