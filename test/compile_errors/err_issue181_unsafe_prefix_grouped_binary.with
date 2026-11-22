//! expect-error: unsafe prefix requires a raw pointer dereference or raw pointer index

fn main:
    let x = 1
    let p = &x as *const i32
    let y = unsafe (*p + 1)
    y
