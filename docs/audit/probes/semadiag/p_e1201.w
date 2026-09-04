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
