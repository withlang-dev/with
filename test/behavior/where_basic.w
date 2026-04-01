//! expect-stdout: ok

trait Printable =
    fn show(self: Self) -> str

type Wrapper { value: i32 }

impl Printable for Wrapper =
    fn show(self: Wrapper) -> str:
        "wrapped"

fn display[T](x: T) -> str where T: Printable:
    x.show()

fn main:
    let w = Wrapper { value: 42 }
    let s = display(w)
    assert(s == "wrapped")
    print("ok")
