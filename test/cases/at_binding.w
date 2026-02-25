// Test @ binding in match patterns

type Shape = Circle(i32) | Rect(i32)

fn area(s: Shape) -> i32 =
    match s
        whole @ Circle(r) -> r * r
        whole @ Rect(w) -> w * w

fn main() -> i32 =
    let c = Circle(3)
    let r = Rect(4)
    assert(area(c) == 9)
    assert(area(r) == 16)
    0
