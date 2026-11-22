//! expect-check-fail: duplicate implementation of trait for type
// §11.4 / §29.12 (E1102): a trait may be implemented at most once for a type.
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
