// POSITIVE: println uses .display() method if available (Display trait)
type Point = {
    x: i32,
    y: i32
}

impl Point =
    fn display(self: Point) -> str: "Point(custom)"

fn main -> i32:
    let p = Point { x: 3, y: 4 }
    let s = Point.display(p)
    assert(s == "Point(custom)")
    // println should use display method
    println(p)
    println("display trait ok")
