//! expect-exit: 134
//! expect-stderr: in the callback

// #3178 (§16.2b.9, Eric 2026-11-18): a panic in a callback does not unwind
// into C. With has no unwinding: the panic reports and aborts the process
// where it is raised, with C's frames still on the stack.
use c_import("static inline int apply(int (*f)(int), int x) { return f ? f(x) : -1; }\n")

c contract lib:
    fn apply
        callback param 0

fn boom(x: c_int) -> c_int:
    if x > 0: panic("in the callback")
    x

fn main:
    print(apply(boom, 21))
