// POSITIVE: trait bounds on generic type parameters (§11.2)
trait Numeric =
    fn to_num(self: Self) -> i32

type Dog = { age: i32 }
type Cat = { age: i32 }

impl Numeric for Dog =
    fn to_num(self: Dog) -> i32: self.age * 2

impl Numeric for Cat =
    fn to_num(self: Cat) -> i32: self.age + 10

fn get_num[T: Numeric](item: T) -> i32:
    item.to_num()

fn main -> i32:
    let d = Dog { age: 5 }
    let c = Cat { age: 3 }
    assert(get_num(d) == 10)
    assert(get_num(c) == 13)
    println("trait bounds ok")
