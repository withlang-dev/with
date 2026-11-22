//! expect-stdout: a! b!
//! expect-stdout: a? b?
//! expect-stdout: 1 2

// A trait's default method is a method of each impl that does not define
// it: what it calls through `self`, the generic instance of a call it makes
// with `self`, and a field it reads are that impl's. One body's nodes were
// shared by every impl, and what Sema recorded for them was the last impl
// checked: `A.shout()` ran B's `name` and printed `b!`.

trait Named:
    fn name(self: &Self) -> str
    fn rank(self: &Self) -> i64
    fn shout(self: &Self) -> str: self.name() ++ "!"
    fn ask(self: &Self) -> str: tag(self) ++ "?"
    fn level(self: &Self) -> i64: self.rank()

fn tag[T: Named](x: &T) -> str: x.name()

type A { x: i64 }
type B { y: i64, z: i64 }

impl Named for A:
    fn name(self: &Self) -> str: "a"
    fn rank(self: &Self) -> i64: self.x

impl Named for B:
    fn name(self: &Self) -> str: "b"
    fn rank(self: &Self) -> i64: self.z

fn main:
    let a = A { x: 1 }
    let b = B { y: 9, z: 2 }
    print(f"{a.shout()} {b.shout()}")
    print(f"{a.ask()} {b.ask()}")
    print(f"{a.level()} {b.level()}")
