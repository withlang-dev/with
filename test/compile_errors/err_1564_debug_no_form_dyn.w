//! expect-check-fail: cannot format a value of type 'dyn Shape' with :? — §15.4.7 gives it no Debug form

// D71 / §15.4.7 (#1564): a `dyn Trait` has no Debug form, even when the
// value behind it is a struct that has one.

trait Shape:
    fn area(self: &Self) -> i32

type Square { side: i32 }

impl Shape for Square:
    fn area(self: &Self) -> i32: self.side * self.side

fn show(s: &dyn Shape):
    print(f"{s:?}")

fn main:
    let q = Square { side: 2 }
    show(&q)
