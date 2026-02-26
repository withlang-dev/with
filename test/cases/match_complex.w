// Test complex match patterns with guards and nested patterns
type Shape = enum {
    Circle(i32),
    Rect(i32, i32),
    Point,
}

fn area(s: Shape) -> i32 =
    match s
        Shape.Circle(r) if r > 0 -> r * r * 3
        Shape.Circle(_) -> 0
        Shape.Rect(w, h) if w == h -> w * w
        Shape.Rect(w, h) -> w * h
        Shape.Point -> 0

fn main() -> i32 =
    println(area(Shape.Circle(5)))
    println(area(Shape.Circle(0)))
    println(area(Shape.Rect(4, 4)))
    println(area(Shape.Rect(3, 5)))
    println(area(Shape.Point))
    0
