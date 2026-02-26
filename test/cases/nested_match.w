// Test: nested match expressions

type Color = Red | Green | Blue
type Shape = Circle(i32) | Rect(i32, i32)

fn describe(s: Shape, c: Color) -> i32 =
    match s
        Circle(r) -> match c
            Red -> r * 100
            Green -> r * 200
            Blue -> r * 300
        Rect(w, h) -> match c
            Red -> w + h
            Green -> (w + h) * 2
            Blue -> (w + h) * 3

fn main() -> i32 =
    println(describe(Circle(5), Red))
    println(describe(Circle(5), Green))
    println(describe(Rect(3, 4), Blue))
    0
