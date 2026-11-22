//! expect-check-fail: method 'shout' is declared for `Box[str]`, and this is a `Box[isize]`
//! expect-check-fail: = help: `shout` exists for that one instantiation; declare it in an `impl[T]` block to have it for every one

// #3508: a method declared for one instantiation is a method of that
// instantiation alone. It was accepted on every other one, and its body
// read the receiver at the wrong type: an integer as text, in safe code.
type Box[T] { v: T }

impl Box[str]:
    fn shout() -> str: self.v.to_upper()

fn main:
    let a = Box { v: "hi" }
    print(a.shout())
    let b = Box { v: 7 }
    print(b.shout())
