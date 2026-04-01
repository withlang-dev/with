//! expect-stdout: ok

trait Showable =
    fn show(self: Self) -> str

trait Sized =
    fn size(self: Self) -> i32

type Box { value: i32 }

impl Showable for Box =
    fn show(self: Box) -> str:
        "box"

impl Sized for Box =
    fn size(self: Box) -> i32:
        4

fn describe[T](x: T) -> str where T: Showable, T: Sized:
    x.show()

fn main:
    let b = Box { value: 42 }
    assert(describe(b) == "box")
    print("ok")
