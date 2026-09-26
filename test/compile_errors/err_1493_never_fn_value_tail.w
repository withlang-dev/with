//! expect-check-fail: a `-> Never` function must not produce a value

// #1493: a valued tail under a declared `Never` return passed Sema and
// failed the MIR validator; it is a return type mismatch at the tail.

fn f -> Never: 5

fn main: f()
