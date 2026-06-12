//! expect-check-fail: transmute expects exactly one argument

fn main:
    let _bad = unsafe { transmute[u32]() }
