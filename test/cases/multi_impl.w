// Test multiple impl blocks for same type
type Point = { x: i32, y: i32 }

impl Point =
    fn new(x: i32, y: i32) -> Point = Point { x: x, y: y }

extend Point =
    fn magnitude_sq(self: Point) -> i32 = self.x * self.x + self.y * self.y

fn main() -> i32 =
    let p = Point.new(3, 4)
    println(p.magnitude_sq())
    0
