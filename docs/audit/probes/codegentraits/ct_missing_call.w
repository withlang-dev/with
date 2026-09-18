//! ct_missing_call: call the OMITTED trait method statically.
//! Expectation under test: must fail loudly (missing impl method).
trait T:
    fn m(self: &Self) -> i32
    fn n(self: &Self) -> i32

type A { v: i32 }

impl T for A:
    fn m(self: &Self) -> i32: 1

fn main:
    let a = A { v: 0 }
    assert(a.n() == 2)
