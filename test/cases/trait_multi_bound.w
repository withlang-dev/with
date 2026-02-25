// Test: Multiple trait bounds on generics
trait Printable =
    fn label(self: Self) -> i32

trait Measurable =
    fn size(self: Self) -> i32

type Item = { name: i32, weight: i32 }

impl Printable for Item =
    fn label(self: Item) -> i32 = self.name

impl Measurable for Item =
    fn size(self: Item) -> i32 = self.weight

fn describe[T: Printable + Measurable](x: T) -> i32 =
    x.label() + x.size()

fn main() -> i32 =
    let item = Item { name: 10, weight: 32 }
    if describe(item) == 42 then 0 else 1
