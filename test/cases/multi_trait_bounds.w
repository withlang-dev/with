// Test multiple trait bounds with + syntax
trait HasName =
    fn name(self: Self) -> str

trait HasAge =
    fn age(self: Self) -> i32

type Person = { n: str, a: i32 }

impl HasName for Person =
    fn name(self: Person) -> str: self.n

impl HasAge for Person =
    fn age(self: Person) -> i32: self.a

fn describe[T: HasName + HasAge](item: T) -> i32:
    println(item.name())
    item.age()

fn main -> i32:
    let p = Person { n: "Alice", a: 30 }
    let age = describe(p)
    println(age)
