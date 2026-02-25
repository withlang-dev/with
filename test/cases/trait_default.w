// Test: Default trait method implementations
trait Describable =
    fn name(self: Self) -> str
    fn describe(self: Self) -> str =
        self.name()

type Dog = { breed: str }
type Cat = { color: str }

impl Describable for Dog
    fn name(self: Dog) -> str =
        self.breed

impl Describable for Cat
    fn name(self: Cat) -> str =
        self.color
    fn describe(self: Cat) -> str =
        "a cat"

fn main() -> i32 =
    let d = Dog { breed: "labrador" }
    let c = Cat { color: "orange" }

    // Dog uses default describe() which calls name()
    let d_desc = Dog.describe(d)
    assert(d_desc.starts_with("labrador"))

    // Cat overrides describe()
    let c_desc = Cat.describe(c)
    assert(c_desc.starts_with("a cat"))

    // name() works for both
    let d_name = Dog.name(d)
    assert(d_name.starts_with("labrador"))
    let c_name = Cat.name(c)
    assert(c_name.starts_with("orange"))

    println("all trait default tests passed")
    0
