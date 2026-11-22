//! expect-error: raw pointer to safe memory abstraction conversion requires unsafe context

fn main:
    let xs: [2]i32 = [1, 2]
    let p = &xs[0] as *const i32
    let r = p as &i32
    r
