//! expect-check-fail: retains param <ref> by param <ref>

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c facade lib:
    fn f
        retains param 1

fn main:
    print("ok")
