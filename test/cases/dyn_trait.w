// Test dynamic dispatch via dyn Trait

trait Greetable =
    fn greet(self) -> i32

type Dog = { age: i32 }
type Cat = { lives: i32 }

impl Greetable for Dog =
    fn greet(self: Dog) -> i32 = self.age

impl Greetable for Cat =
    fn greet(self: Cat) -> i32 = self.lives * 10

fn call_greet(g: dyn Greetable) -> i32 =
    g.greet()

fn main() -> i32 =
    let d = Dog { age: 42 }
    let c = Cat { lives: 9 }
    let r1 = call_greet(d)
    let r2 = call_greet(c)
    assert(r1 == 42)
    assert(r2 == 90)
    0
