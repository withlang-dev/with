trait Speak =
    fn speak(self: Self) -> i32

type Dog = { n: i32 }

impl Speak for Dog =
    fn speak(self: Dog) -> i32: self.n

fn main -> i32:
    let d = Dog { n: 5 }
    let x: Box[dyn Speak] = d
    assert(x.speak() == 5)
