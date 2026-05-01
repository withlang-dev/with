//! expect-stdout: ok

fn main:
    var buf: [4]u8 = [0 as u8; 4]
    let p: *mut u8 = (&raw mut buf[0] as *mut u8)
    unsafe:
        p[0] = 42 as u8
        p[1] = 7 as u8
    assert(buf[0] == 42 as u8)
    assert(buf[1] == 7 as u8)
    print("ok")
