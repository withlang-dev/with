// Test Display trait integration with println
type Point = {
    x: i32,
    y: i32
}

impl Point =
    fn display(self: Point) -> str = "Point(custom)"
    fn sum(self: Point) -> i32 = self.x + self.y

type Color = {
    r: i32,
    g: i32,
    b: i32
}

impl Color =
    fn to_string(self: Color) -> str = "Color(rgb)"

fn main() -> i32 =
    let p = Point { x: 3, y: 4 }
    // display method works directly
    let s = Point.display(p)
    assert(s == "Point(custom)")
    assert(Point.sum(p) == 7)

    // println uses display method (prints "Point(custom)")
    println(p)

    // to_string also works as Display fallback
    let c = Color { r: 255, g: 128, b: 0 }
    let cs = Color.to_string(c)
    assert(cs == "Color(rgb)")
    println(c)

    println("all display trait tests passed")
    0
