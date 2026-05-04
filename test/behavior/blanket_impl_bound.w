//! expect-check-fail: does not implement trait

trait Readable:
    fn read(self: &Self) -> str

trait Parseable:
    fn parse(self: &Self) -> str

impl[T: Readable] Parseable for T:
    fn parse(self: T) -> str:
        self.read()

type Opaque { value: i32 }

// Opaque does NOT implement Readable, so blanket impl doesn't apply
fn try_parse[T: Parseable](x: T) -> i32:
    1

fn main:
    let o = Opaque { value: 1 }
    try_parse(o)
