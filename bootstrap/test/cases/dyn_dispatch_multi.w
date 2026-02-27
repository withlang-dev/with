// Test dynamic dispatch with multiple methods
trait Shape =
    fn area(self: Self) -> i32
    fn name(self: Self) -> str

type Circle = { radius: i32 }
type Square = { side: i32 }

impl Shape for Circle =
    fn area(self: Circle) -> i32: self.radius * self.radius * 3
    fn name(self: Circle) -> str: "circle"

impl Shape for Square =
    fn area(self: Square) -> i32: self.side * self.side
    fn name(self: Square) -> str: "square"

fn print_shape(s: dyn Shape) -> void:
    println(s.name())
    println(s.area())

fn main -> i32:
    let c = Circle { radius: 5 }
    let s = Square { side: 4 }
    print_shape(c)
    print_shape(s)
    0
