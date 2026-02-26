// Test: enum with impl methods

type Shape = Circle(i32) | Rect(i32, i32) | Point

impl Shape
    fn area(self: Shape) -> i32 =
        match self
            Circle(r) -> r * r * 3
            Rect(w, h) -> w * h
            Point -> 0

    fn is_empty(self: Shape) -> bool =
        match self
            Point -> true
            _ -> false

fn main() -> i32 =
    let c = Circle(5)
    let r = Rect(3, 4)
    let p = Point

    println(Shape.area(c))
    println(Shape.area(r))
    println(Shape.area(p))

    assert(not Shape.is_empty(c))
    assert(Shape.is_empty(p))
    println("ok")
    0
