// Integration test: structs with methods, record update, pipeline
type Point = { x: i32, y: i32 }

impl Point =
    fn new(x: i32, y: i32) -> Point = Point { x: x, y: y }
    fn translate(self: Point, dx: i32, dy: i32) -> Point =
        { self with x: self.x + dx, y: self.y + dy }
    fn scale(self: Point, factor: i32) -> Point =
        Point { x: self.x * factor, y: self.y * factor }
    fn distance_sq(self: Point) -> i32 =
        self.x * self.x + self.y * self.y

fn main() -> i32 =
    let p = Point.new(1, 2)
    let p2 = p.translate(3, 4)
    let p3 = p2.scale(2)
    println(p3.x)
    println(p3.y)
    println(p3.distance_sq())
    0
