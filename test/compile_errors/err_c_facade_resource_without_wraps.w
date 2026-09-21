//! expect-check-fail: expected 'wraps <representation>'

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c facade lib:
    resource H
        drop close

fn main:
    print("ok")
