//! expect-error: raw pointer dereference requires unsafe context

fn main:
    let x = 1
    let y = 2
    let p = &x as *const i32
    let q = &y as *const i32
    let z = unsafe *p + *q
    z
