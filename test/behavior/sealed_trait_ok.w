//! expect-stdout: ok
extern fn print(s: str) -> void

@[sealed]
trait Shape =
    fn area(self: Self) -> i32

type Circle { radius: i32 }

impl Shape for Circle =
    fn area(self: Circle) -> i32:
        self.radius * self.radius * 3

fn main:
    let c = Circle { radius: 5 }
    assert(c.area() == 75)
    print("ok")
