//! expect-error: where clause references unknown type parameter 'U'
trait Printable =
    fn show(self: &Self) -> str

fn display[T](x: T) -> str where U: Printable:
    "hello"

fn main:
    let s = display(42)
