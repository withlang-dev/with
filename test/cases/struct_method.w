// Test struct with methods
type Point = {
    x: i32,
    y: i32,
}

fn Point.new(x: i32, y: i32) -> Point =
    Point { x: x, y: y }

fn Point.manhattan(self: Point) -> i32 =
    let ax = if self.x < 0 then 0 - self.x else self.x
    let ay = if self.y < 0 then 0 - self.y else self.y
    ax + ay

fn main() -> i32 =
    let p = Point.new(3, -4)
    println(p.x)
    println(p.y)
    println(Point.manhattan(p))
    0
