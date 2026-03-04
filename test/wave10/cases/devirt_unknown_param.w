trait Speak =
    fn speak(self: Self) -> i32

type Dog = { n: i32 }

impl Speak for Dog =
    fn speak(self: Dog) -> i32: self.n

fn call(x: Box[dyn Speak]) -> i32:
    x.speak()

fn main -> i32:
    let d = Dog { n: 5 }
    assert(call(d) == 5)
