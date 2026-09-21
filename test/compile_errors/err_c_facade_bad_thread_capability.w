//! expect-check-fail: thread capabilities are

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c facade lib:
    resource H wraps *mut u8
        thread background

fn main:
    print("ok")
