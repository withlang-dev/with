//! expect-check-fail: cannot compare pointer and array

fn main:
    let arr: [4]i32 = [1, 2, 3, 4]
    let p: *const i32 = (&arr[0] as *const i32)
    if p != arr:
        return
