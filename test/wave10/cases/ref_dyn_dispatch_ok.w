trait Speak =
    fn speak(self: Self) -> i32

type Dog = { n: i32 }

impl Speak for Dog =
    fn speak(self: Dog) -> i32: self.n

fn call_ref(x: &dyn Speak) -> i32:
    x.speak()

fn main -> i32:
    let d = Dog { n: 7 }
    assert(call_ref(&d) == 7)
    let r = &d
    assert(call_ref(r) == 7)
