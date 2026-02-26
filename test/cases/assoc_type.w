trait Container =
    type Item
    fn len(self: &Self) -> i32

trait Printable =
    type Output = str
    fn to_output(self: &Self) -> str

fn main() -> i32 =
    println("associated types parsed")
    0
