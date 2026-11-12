//! expect-check-fail: expected 'param <name>'

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c contract lib:
    fn f
        consumes 4

fn main:
    print("ok")
