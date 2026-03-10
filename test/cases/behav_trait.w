//! expect-stdout: ok
extern fn print(s: str) -> void

// Behavior test: traits — declaration, impl, method dispatch

trait Describable =
    fn describe(self: Self) -> str

type Circle = { radius: i32 }
type Square = { side: i32 }

impl Describable for Circle =
    fn describe(self: Circle) -> str:
        "circle"

impl Describable for Square =
    fn describe(self: Square) -> str:
        "square"

fn test_trait_dispatch:
    let c = Circle { radius: 5 }
    let s = Square { side: 10 }
    assert(c.describe() == "circle")
    assert(s.describe() == "square")

trait HasArea =
    fn area(self: Self) -> i32

impl HasArea for Circle =
    fn area(self: Circle) -> i32:
        self.radius * self.radius * 3

impl HasArea for Square =
    fn area(self: Square) -> i32:
        self.side * self.side

fn test_trait_with_fields:
    let c = Circle { radius: 4 }
    let s = Square { side: 5 }
    assert(c.area() == 48)
    assert(s.area() == 25)

fn test_multiple_impls:
    let c = Circle { radius: 3 }
    assert(c.describe() == "circle")
    assert(c.area() == 27)

fn main:
    test_trait_dispatch()
    test_trait_with_fields()
    test_multiple_impls()
    print("ok")
