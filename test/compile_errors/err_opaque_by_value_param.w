//! expect-check-fail: opaque types cannot be passed by value; use a pointer or reference

type FILE = opaque

fn consume(file: FILE):
    let _ = file
