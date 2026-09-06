//! ct_missing_dyn: dyn-dispatch the OMITTED trait method.
//! Expectation under test: must fail loudly, never a null-slot trap.
trait T:
    fn m(self: &Self) -> i32
    fn n(self: &Self) -> i32

type A { v: i32 }

impl T for A:
    fn m(self: &Self) -> i32: 1

fn call_n(x: &dyn T) -> i32:
    x.n()

fn main:
    let a = A { v: 0 }
    assert(call_n(&a) == 2)
