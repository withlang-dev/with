//! expect-check-fail: unknown facade clause 'owns'

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c facade lib:
    resource H wraps *mut u8
        owns thing

fn main:
    print("ok")
