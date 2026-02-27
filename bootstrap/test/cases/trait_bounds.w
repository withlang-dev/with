// Test trait bounds on generic type parameters
trait Printable =
    fn to_num(self: Self) -> i32

type Dog = { age: i32 }
type Cat = { age: i32 }

impl Printable for Dog =
    fn to_num(self: Dog) -> i32:
        self.age * 2

impl Printable for Cat =
    fn to_num(self: Cat) -> i32:
        self.age + 10

fn get_num[T: Printable](item: T) -> i32:
    item.to_num()

fn main -> i32:
    let d = Dog { age: 5 }
    let c = Cat { age: 3 }
    println(get_num(d))
    println(get_num(c))
