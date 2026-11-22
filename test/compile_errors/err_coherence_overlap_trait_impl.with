//! expect-check-fail: overlapping implementations of 'T'
// §11.4 / §29.12 (E1201): a direct impl and a blanket impl that both apply to
// the same type overlap and are rejected.
trait T:
    fn m(self: &Self) -> i32

type A { n: i32 }

impl T for A:
    fn m(self: &Self) -> i32: 1

impl[X] T for X:
    fn m(self: &Self) -> i32: 0

fn main:
    let a = A { n: 0 }
    let _ = a.m()
