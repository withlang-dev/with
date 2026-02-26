// Test: Generic functions with trait bounds
trait Summable =
    fn value(self: Self) -> i32

type Wrapper = { n: i32 }

impl Summable for Wrapper =
    fn value(self: Wrapper) -> i32: self.n

fn add_values[T: Summable](a: T, b: T) -> i32:
    a.value() + b.value()

fn main -> i32:
    let a = Wrapper { n: 20 }
    let b = Wrapper { n: 22 }
    let result = add_values(a, b)
    if result == 42 then 0 else 1
