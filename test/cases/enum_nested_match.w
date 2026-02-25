// Test: match on enum inside if/else
type Color = Red | Green | Blue

fn color_value(c: Color) -> i32 =
    match c
        Red -> 1
        Green -> 2
        Blue -> 3

type Shape = Circle(i32) | Square(i32)

fn area(s: Shape) -> i32 =
    match s
        Circle(r) -> r * r
        Square(w) -> w * w

fn main() -> i32 =
    let c = Green
    let val = color_value(c)

    // match inside if/else
    let result = if val == 2:
        let s = Circle(5)
        area(s)
    else
        0

    assert(result == 25)

    // nested: use match result in another condition
    let s1 = Square(4)
    let s2 = Circle(3)
    let a1 = area(s1)
    let a2 = area(s2)

    if a1 > a2:
        assert(a1 == 16)
        assert(a2 == 9)
    else
        assert(false)

    // match on enum, then use result
    let picked = Blue
    let multiplier = match picked
        Red -> 10
        Green -> 20
        Blue -> 30

    assert(multiplier == 30)

    println("all enum nested match tests passed")
    0
