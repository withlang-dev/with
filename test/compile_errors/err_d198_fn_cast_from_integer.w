//! expect-check-fail: to the function type `fn(i32) -> i32` requires unsafe context
// D198: a function value is called without unsafe, so the cast that makes one from an integer is the gate.
type Holder:
    f: fn(i32) -> i32

fn call(h: Holder) -> i32: (h.f)(1)

fn main:
    print(f"{call(Holder { f: 4096 as fn(i32) -> i32 })}")
