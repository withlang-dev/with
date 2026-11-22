//! expect-error: raw pointer indexing requires unsafe context

fn main:
    let arr: [4]i32 = [1, 2, 3, 4]
    let p: *const i32 = (&arr[0] as *const i32)
    let x = p[1]
    x
