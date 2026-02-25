// Test: Trait default methods
trait Greeter =
    fn name(self: Self) -> i32
    fn greet(self: Self) -> i32 = self.name() + 1

type Robot = { id: i32 }

impl Greeter for Robot =
    fn name(self: Robot) -> i32 = self.id

fn main() -> i32 =
    let r = Robot { id: 41 }
    if r.greet() == 42 then 0 else 1
