trait Show =
    fn show(self: Self) -> i32

type Foo = {
    x: i32,
}

fn require_show[T: Show](x: T) -> T:
    x

fn main -> i32:
    let f = Foo { x: 1 }
    let _ = require_show(f)
    0
