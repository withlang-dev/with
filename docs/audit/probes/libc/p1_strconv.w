use std.libc

fn main:
    let null_ep = 0 as *mut *mut i8
    assert(strtol(c"12345".ptr, null_ep, 10) == 12345)
    assert(strtol(c"0x10".ptr, null_ep, 0) == 16)
    assert(strtol(c"-7".ptr, null_ep, 10) == -7)
    assert(strtoul(c"4294967295".ptr, null_ep, 10) == 4294967295)
    assert(strtod(c"3.5".ptr, null_ep) == 3.5)
    var ep: *mut i8 = 0 as *mut i8
    assert(strtol(c"12x".ptr, &raw mut ep, 10) == 12)
    assert(unsafe *ep == 120)
    print("ok")
