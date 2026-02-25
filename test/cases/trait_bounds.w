// Test: trait bounds on generic functions
trait Sizeable =
    fn size(self: Self) -> i32

type Circle = {
    radius: i32,
}

type Square = {
    side: i32,
}

impl Sizeable for Circle =
    fn size(self: Circle) -> i32 =
        self.radius * self.radius * 3

impl Sizeable for Square =
    fn size(self: Square) -> i32 =
        self.side * self.side

fn get_size[T: Sizeable](x: T) -> i32 =
    x.size()

fn main() -> i32 =
    let c = Circle { radius: 5 }
    let s = Square { side: 4 }
    let cs = get_size(c)
    let ss = get_size(s)
    assert(cs == 75)
    assert(ss == 16)
    0
