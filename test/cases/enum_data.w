type Shape = Circle(i32) | Rect(i32)

fn area(s: Shape) -> i32:
    match s
        Circle(r) -> r * r
        Rect(w) -> w * 2

fn main -> i32:
    let c = Circle(5)
    let r = Rect(6)
    assert(area(c) + area(r) + 5 == 42)
