//! expect-error: raw pointer as_option() expects no arguments

fn main:
    let p: *mut i32 = null
    let _ = p.as_option(1)
