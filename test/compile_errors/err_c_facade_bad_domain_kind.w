//! expect-check-fail: a domain is 'process', 'thread', 'resource' or 'static'

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c facade lib:
    domain errno global

fn main:
    print("ok")
