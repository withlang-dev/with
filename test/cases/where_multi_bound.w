// Test where clause with multiple bounds
trait Addable =
    fn add_val(self: Self) -> i32

trait Showable =
    fn show_val(self: Self) -> str

type Item = { v: i32, label: str }

impl Addable for Item =
    fn add_val(self: Item) -> i32 = self.v

impl Showable for Item =
    fn show_val(self: Item) -> str = self.label

fn process[T](x: T) -> i32 where T: Addable + Showable =
    println(x.show_val())
    x.add_val()

fn main() -> i32 =
    let item = Item { v: 42, label: "answer" }
    let result = process(item)
    println(result)
    0
