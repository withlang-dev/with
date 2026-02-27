// Test: Match expression with enum payloads
type Shape = Circle(i32) | Rect(i32) | Point

fn area(s: Shape) -> i32:
    match s
        Circle(r) -> r * r
        Rect(w) -> w * w
        Point -> 0

fn main -> i32:
    let c = Circle(5)
    let r = Rect(3)
    let p = Point
    assert(area(c) == 25)
    assert(area(r) == 9)
    assert(area(p) == 0)
