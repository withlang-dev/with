//! expect-check-fail: arrays do not decay to pointers

fn main:
    var bytes: [4]u8 = [1, 2, 3, 4]
    let p = bytes as *mut u8
    unsafe: *p = 9
