//! expect-check-fail: unknown facade clause 'owns'
//! expect-check-fail: = help: move the statement inside `fn main`, or remove `fn main` to use implicit main mode

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c contract lib:
    resource H wraps *mut u8
        owns thing

fn main:
    print("ok")
