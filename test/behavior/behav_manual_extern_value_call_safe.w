//! expect-stdout: ok

extern "C" fn abs(x: i32) -> i32

fn main:
    assert(abs(-7) == 7)
    assert(unsafe { abs(-8) } == 8)
    print("ok")
