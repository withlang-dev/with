//! expect-check-fail: expected 'resource', 'fn', 'domain' or 'use convention'

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c facade lib:
    type T { n: i32 }

fn main:
    print("ok")
