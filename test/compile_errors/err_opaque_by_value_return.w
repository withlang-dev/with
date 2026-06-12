//! expect-check-fail: opaque types cannot be returned by value; use a pointer or reference

type FILE = opaque

fn make_file() -> FILE:
    unreachable()
