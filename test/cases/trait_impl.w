// Test trait declarations and impl blocks
trait Describable =
    fn describe(self) -> str

type Dog = {
    name: str,
    age: i32,
}

impl Describable for Dog =
    fn describe(self: Dog) -> str = self.name

fn main() -> i32 =
    let d = Dog { name: "Rex", age: 5 }
    println(Dog.describe(d))
    println(d.name)
    println(d.age)
    0
