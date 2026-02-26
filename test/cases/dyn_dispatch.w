// Test dynamic dispatch with dyn Trait

trait Describable =
    fn describe(self: Self) -> i32

type Circle = {
    radius: i32,
}

type Square = {
    side: i32,
}

impl Describable for Circle =
    fn describe(self: Circle) -> i32 = self.radius

impl Describable for Square =
    fn describe(self: Square) -> i32 = self.side

fn get_value(obj: dyn Describable) -> i32 =
    obj.describe()

fn main() -> i32 =
    let c = Circle { radius: 5 }
    let s = Square { side: 10 }

    assert(get_value(c) == 5)
    assert(get_value(s) == 10)
    0
