// Test trait with default method implementations
trait Describable =
    fn kind(self: Self) -> i32
    fn describe(self: Self) -> i32:
        self.kind() * 10

type Widget = { id: i32 }

impl Describable for Widget =
    fn kind(self: Widget) -> i32: self.id

fn main -> i32:
    let w = Widget { id: 5 }
    println(w.kind())
    println(w.describe())
