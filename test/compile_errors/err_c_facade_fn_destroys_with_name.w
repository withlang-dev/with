//! expect-check-fail: 'destroys <fn>' is a resource clause: the resource owns the fact, and an fn item does not state it
//! expect-check-fail: = help: move the statement inside `fn main`, or remove `fn main` to use implicit main mode

// D51 §16.2b stage 1: a malformed facade clause is a parse error.

c contract lib:
    fn close
        destroys close

fn main:
    print("ok")
