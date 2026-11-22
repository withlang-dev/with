//! expect-check-fail: impl of `T` for `A` does not define `n`, which the trait declares with no default body
// #1002: an impl that leaves out a required trait method was accepted, and
// a call through `&dyn` reached a null vtable slot and trapped (rc=133)
// with no diagnostic.
trait T:
    fn m(self: &Self) -> i32
    fn n(self: &Self) -> i32

type A { v: i32 }

impl T for A:
    fn m(self: &Self) -> i32: 1

fn call_n(x: &dyn T) -> i32: x.n()

fn main:
    let a = A { v: 0 }
    print(call_n(&a))
