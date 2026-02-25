// Test Display trait integration with println

type Point = { x: i32, y: i32 }

impl Point =
    fn display(self: Point) -> str = "Point(custom)"

    fn to_string(self: Point) -> str = "unused"

fn main() -> i32 =
    let p = Point { x: 3, y: 4 }
    println(p)
    0
