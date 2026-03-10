//! expect-stdout: ok
extern fn print(s: str) -> void

trait Transform =
    type Output = i32
    fn apply(self: Self) -> i32

type Doubler = { value: i32 }

// Impl without providing Output — default should be accepted
impl Transform for Doubler =
    fn apply(self: Doubler) -> i32:
        self.value * 2

fn main:
    let d = Doubler { value: 21 }
    assert(d.apply() == 42)
    print("ok")
