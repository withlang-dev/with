// Test: generic type parameter with multiple trait bounds
trait A =
    fn a(self: Self) -> i32

trait B =
    fn b(self: Self) -> i32

type X = {
    v: i32,
}

impl A for X =
    fn a(self: X) -> i32 = self.v

impl B for X =
    fn b(self: X) -> i32 = self.v + 1

fn sum[T: A + B](x: T) -> i32 =
    x.a() + x.b()

fn main() -> i32 =
    let x = X { v: 20 }
    assert(sum(x) == 41)
    0
