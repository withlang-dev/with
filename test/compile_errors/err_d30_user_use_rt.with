//! expect-check-fail: is the compiler's runtime, internal to the standard library

// D30 step 3: the runtime is a module the standard library imports
// (`use rt.rt_core`), never a program — `with_*` was never user-facing
// (plan §9 open question 3). A program reaches the runtime through std.
use rt.rt_core

fn main:
    print(with_f64_to_string(1.5))
