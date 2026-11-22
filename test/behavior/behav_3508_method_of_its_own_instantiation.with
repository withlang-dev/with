//! expect-stdout: HI
//! expect-stdout: HI
//! expect-stdout: true
//! expect-stdout: HI

// #3508: a method declared for `Box[str]` is callable on a `Box[str]`, by a
// call, through a borrow, and as a method value; a method of `impl[T]` is
// callable on every instantiation.
type Box[T] { v: T }

impl Box[str]:
    fn shout() -> str: self.v.to_upper()

impl[T] Box[T]:
    fn has() -> bool: true

fn loud(b: &Box[str]) -> str: b.shout()

fn main:
    let a = Box { v: "hi" }
    print(a.shout())
    print(loud(a))
    let b = Box { v: 7 }
    print(b.has())
    let f = Box[str].shout
    print(f(a))
