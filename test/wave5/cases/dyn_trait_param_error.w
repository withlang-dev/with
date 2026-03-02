trait Describable =
    fn describe(self: Self) -> i32

type Circle = {
    radius: i32,
}

type Triangle = {
    side: i32,
}

impl Describable for Circle =
    fn describe(self: Circle) -> i32:
        self.radius

fn get_value(obj: dyn Describable) -> i32:
    obj.describe()

fn main -> i32:
    let t = Triangle { side: 7 }
    let _ = get_value(t)
    0
