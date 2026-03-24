//! expect-stdout: ok
// Verify parser accepts impl Trait for Type[args] syntax
// and sema resolves the generic impl target correctly.
trait Describable =
    fn describe(self: Self) -> i32

type Box { value: i32 }

impl Describable for Box =
    fn describe(self: Box) -> i32: self.value

fn main:
    let b = Box { value: 10 }
    assert(b.describe() == 10)
    print("ok")
