// Test: multiple trait implementations and method dispatch
trait Displayable =
    fn display(self: Self) -> i32

trait Sizeable =
    fn size(self: Self) -> i32

type Circle = {
    radius: i32,
}

type Square = {
    side: i32,
}

impl Displayable for Circle =
    fn display(self: Circle) -> i32 =
        self.radius

impl Sizeable for Circle =
    fn size(self: Circle) -> i32 =
        self.radius * self.radius * 3

impl Displayable for Square =
    fn display(self: Square) -> i32 =
        self.side

impl Sizeable for Square =
    fn size(self: Square) -> i32 =
        self.side * self.side

fn main() -> i32 =
    let c = Circle { radius: 5 }
    let s = Square { side: 4 }
    let cd = c.display()
    let cs = c.size()
    let sd = s.display()
    let ss = s.size()
    assert(cd == 5)
    assert(cs == 75)
    assert(sd == 4)
    assert(ss == 16)
    0
