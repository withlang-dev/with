//! expect-check-fail: transmute source and target sizes differ: i32 is 4 byte(s), i64 is 8 byte(s)

fn main:
    let _bad = unsafe { transmute[i64](42 as i32) }
