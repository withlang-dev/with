//! expect-stdout: ok

fn main:
    let xs: [2]i32 = [1, 2]
    let p = &xs[0] as *const i32
    let r = unsafe { p as &i32 }
    assert(*r == 1)
    print("ok")
