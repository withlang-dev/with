//! expect-error: does not implement trait

trait Printable =
    fn show(self: Self) -> str

type Wrapper { value: i32 }

// Wrapper does NOT impl Printable

fn display[T](x: T) -> str where T: Printable:
    x.show()

fn main:
    let w = Wrapper { value: 42 }
    let s = display(w)
    print(s)
