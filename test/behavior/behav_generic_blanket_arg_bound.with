//! expect-stdout: ok

trait Named:
    fn name(self: &Self) -> str

trait WrapNamed:
    fn marker(self: &Self) -> i32

type Box[T] { value: T }
type Person { name: str }

impl Named for Person:
    fn name(self: &Self) -> str:
        self.name

impl[T: Named] WrapNamed for Box[T]:
    fn marker(self: &Self) -> i32:
        1

fn need_wrap_named[T: WrapNamed](x: T) -> i32:
    1

fn main:
    let p = Box { value: Person { name: "Ada" } }
    assert(need_wrap_named(p) == 1)
    print("ok")
