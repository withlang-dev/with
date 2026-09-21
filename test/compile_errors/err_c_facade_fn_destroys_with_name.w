//! expect-check-fail: takes no name

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c facade lib:
    fn close
        destroys close

fn main:
    print("ok")
