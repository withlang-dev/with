// Test complex match patterns with guards on same variant
type Shape = Circle(i32) | Rect(i32, i32) | Point

fn area(s: Shape) -> i32 =
    match s
        Circle(r) if r > 0 -> r * r * 3
        Circle(_) -> 0
        Rect(w, h) if w == h -> w * w
        Rect(w, h) -> w * h
        Point -> 0

fn main() -> i32 =
    println(area(Circle(5)))
    println(area(Circle(0)))
    println(area(Rect(4, 4)))
    println(area(Rect(3, 5)))
    println(area(Point))
    0
