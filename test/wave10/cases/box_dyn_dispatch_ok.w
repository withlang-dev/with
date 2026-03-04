trait Speak =
    fn speak(self: Self) -> i32

type Dog = { n: i32 }
type Cat = { n: i32 }

impl Speak for Dog =
    fn speak(self: Dog) -> i32: self.n

impl Speak for Cat =
    fn speak(self: Cat) -> i32: self.n * 2

fn call_box(x: Box[dyn Speak]) -> i32:
    x.speak()

fn main -> i32:
    let d = Dog { n: 9 }
    let c = Cat { n: 5 }
    assert(call_box(d) == 9)
    assert(call_box(c) == 10)
