type Point = { x: i32, y: i32 }
impl Point =
    fn eq(self: Point, other: Point) -> bool:
        self.x == other.x and self.y == other.y

fn main -> i32:
    let a = Point { x: 1, y: 2 }
    let b = Point { x: 1, y: 2 }
    let c = Point { x: 3, y: 4 }
    println(a == b)
    println(a == c)
