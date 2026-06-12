//! expect-check-fail: unreachable() expects zero or one message argument

fn main:
    unreachable("first", "second")
