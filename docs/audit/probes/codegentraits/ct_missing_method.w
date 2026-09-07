//! ct_missing_method: impl omits a required method with no default.
//! expect-check-fail (missing method must be loud, never a null vtable slot).
trait T:
    fn m(self: &Self) -> i32
    fn n(self: &Self) -> i32

type A { v: i32 }

impl T for A:
    fn m(self: &Self) -> i32: 1

fn main:
    let a = A { v: 0 }
    assert(a.m() == 1)
