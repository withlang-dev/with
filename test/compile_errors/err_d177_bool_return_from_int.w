//! expect-check-fail: type mismatch

// D177 (§4.2a): a `bool` return does not take an integer.
fn ready(count: i32) -> bool: count
fn main:
    print(f"{ready(1)}")
