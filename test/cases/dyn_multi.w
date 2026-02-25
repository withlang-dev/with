// Test dynamic dispatch with multiple methods in a trait

trait Shape =
    fn area(self) -> i32
    fn perimeter(self) -> i32

type Circle = { radius: i32 }
type Rect = { w: i32, h: i32 }

impl Shape for Circle =
    fn area(self: Circle) -> i32 = self.radius * self.radius * 3
    fn perimeter(self: Circle) -> i32 = self.radius * 2 * 6

impl Shape for Rect =
    fn area(self: Rect) -> i32 = self.w * self.h
    fn perimeter(self: Rect) -> i32 = (self.w + self.h) * 2

fn print_area(s: dyn Shape) -> i32 =
    s.area()

fn print_perimeter(s: dyn Shape) -> i32 =
    s.perimeter()

fn main() -> i32 =
    let c = Circle { radius: 5 }
    let r = Rect { w: 3, h: 4 }
    assert(print_area(c) == 75)
    assert(print_area(r) == 12)
    assert(print_perimeter(c) == 60)
    assert(print_perimeter(r) == 14)
    0
