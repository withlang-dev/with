// Test: Advanced dynamic dispatch with multiple trait methods
trait Shape =
    fn area(self: Self) -> i32
    fn perimeter(self: Self) -> i32

type Rect = { w: i32, h: i32 }
type Square = { side: i32 }

impl Shape for Rect =
    fn area(self: Rect) -> i32: self.w * self.h
    fn perimeter(self: Rect) -> i32: 2 * (self.w + self.h)

impl Shape for Square =
    fn area(self: Square) -> i32: self.side * self.side
    fn perimeter(self: Square) -> i32: 4 * self.side

fn describe(s: dyn Shape) -> i32:
    s.area() + s.perimeter()

fn main -> i32:
    let r = Rect { w: 3, h: 4 }
    let s = Square { side: 5 }

    assert(describe(r) == 26)
    assert(describe(s) == 45)

