//! expect-check-fail: transmute requires known-size types

type FILE = opaque

fn main:
    let _bad = unsafe { transmute[FILE](0 as i32) }
