//! expect-check-fail: field access requires a concrete struct or union type; this type is opaque

type FILE = opaque

fn main:
    let p: *mut FILE = null
    let _field = unsafe { (*p).fd }
