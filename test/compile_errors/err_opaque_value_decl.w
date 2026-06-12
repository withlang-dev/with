//! expect-check-fail: cannot create value of opaque type; use a pointer or reference

type FILE = opaque

fn main:
    var file: FILE
