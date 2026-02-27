type Dog = {
    age: i32
}

type Cat = {
    age: i32
}

trait Animal =
    fn speak(self: Self) -> i32

impl Animal for Dog =
    fn speak(self: Dog) -> i32:
        self.age * 2

impl Animal for Cat =
    fn speak(self: Cat) -> i32:
        self.age + 4

fn main -> i32:
    let d = Dog { age: 7 }
    let c = Cat { age: 24 }
    assert(d.speak() + c.speak() == 42)
