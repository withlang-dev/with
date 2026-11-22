//! expect-check-fail: Box[NoName]
//! expect-check-fail: does not implement trait 'WrapNamed'

trait Named:
    fn name(self: &Self) -> str

trait WrapNamed:
    fn marker(self: &Self) -> i32

type Box[T] { value: T }
type NoName { value: i32 }

impl[T: Named] WrapNamed for Box[T]:
    fn marker(self: &Self) -> i32:
        1

fn need_wrap_named[T: WrapNamed](x: T) -> i32:
    1

fn main:
    let bad = Box { value: NoName { value: 1 } }
    need_wrap_named(bad)
