use std.libc

fn main:
    var buf: [32]i8 = [0 as i8; 32]
    let p = (&raw mut buf) as *mut [32]i8 as *mut i8
    let n = snprintf(p, 32 as u64, c"%d=%s".ptr, 40, c"two".ptr)
    assert(n == 6)
    assert(unsafe *p == 52)
    assert(unsafe *(p + 1) == 48)
    assert(unsafe *(p + 2) == 61)
    print("ok")
