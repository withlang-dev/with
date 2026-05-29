//! expect-stdout: ok

fn main:
    let bits: u32 = unsafe { transmute[u32](3 as i32) }
    let back: i32 = unsafe { transmute[i32](bits) }
    assert(back == 3)
    print("ok\n")
