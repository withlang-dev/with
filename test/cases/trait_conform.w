// Test: trait conformance — all methods implemented
trait Printable =
    fn show(self: Self) -> i32

type Box = {
    value: i32,
}

impl Printable for Box =
    fn show(self: Box) -> i32:
        self.value

fn main -> i32:
    let b = Box { value: 42 }
    let v = b.show()
    assert(v == 42)
