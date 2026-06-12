//! expect-check-fail: null is not an integer; use a typed pointer context

fn main:
    if null == 0:
        print("bad")
