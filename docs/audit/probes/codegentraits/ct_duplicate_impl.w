//! ct_duplicate_impl: same trait twice for one type (ambiguous impl).
//! expect-check-fail: duplicate implementation of trait for type
trait T:
    fn m(self: &Self) -> i32

type A { n: i32 }

impl T for A:
    fn m(self: &Self) -> i32: 1

impl T for A:
    fn m(self: &Self) -> i32: 2

fn main:
    let a = A { n: 0 }
    let _ = a.m()
