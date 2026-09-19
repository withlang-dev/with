//! expect-check-fail: 'P.new' takes `self`, and this call has no receiver

// #1201: inside an impl, `fn new()` is an instance method. `P.new()` passed no
// receiver, Sema accepted it, and LLVM verification failed.
type P { n: i32 }

impl P:
    fn new() -> P: P { n: 0 }

fn main:
    let p = P.new()
    print(f"{p.n}")
