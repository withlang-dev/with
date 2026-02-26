type Point = { x: i32, y: i32 }

impl Point =
    fn add(self: &Point, other: &Point) -> Point =
        Point { x: self.x + other.x, y: self.y + other.y }

    fn scale(self: &Point, factor: i32) -> Point =
        Point { x: self.x * factor, y: self.y * factor }

fn main() -> i32 =
    let a = Point { x: 1, y: 2 }
    let b = Point { x: 3, y: 4 }
    let c = a.add(&b)
    println(c.x)
    println(c.y)
    let d = a.scale(3)
    println(d.x)
    println(d.y)
    0
