// Test complex match patterns with enums
type Shape = Circle(i32) | Rect(i32, i32) | Point

fn area(s: Shape) -> i32 =
    match s
        Circle(r) -> r * r * 3
        Rect(w, h) -> w * h
        Point -> 0

fn main() -> i32 =
    println(area(Circle(5)))
    println(area(Rect(3, 5)))
    println(area(Point))
    0
