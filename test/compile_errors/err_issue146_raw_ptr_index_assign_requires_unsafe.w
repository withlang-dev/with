//! expect-error: raw pointer indexing requires unsafe context

fn main:
    var arr: [4]i32 = [1, 2, 3, 4]
    let p: *mut i32 = (&mut arr[0] as *mut i32)
    p[1] = 9
