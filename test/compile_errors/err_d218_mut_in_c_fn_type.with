//! expect-check-fail: a C function pointer type has no `mut` parameter: C has no modes, and a C callback that writes through its argument takes `*mut T` (§3.8a)

// D218: no `mut` in an `extern "C"` function type.
type Bag { n: i32 }
fn f(g: extern "C" fn(mut Bag) -> i32) -> i32: 0
fn main: print(1)
