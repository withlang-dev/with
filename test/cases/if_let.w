// Test if-let expressions

type Shape = Circle(f64) | Square(f64) | Point

fn area(s: Shape) -> f64:
    if let Circle(r) = s:
        3.14159 * r * r
    else
        if let Square(side) = s:
            side * side
        else
            0.0

fn main -> i32:
    let c = Circle(2.0)
    let s = Square(3.0)
    let p = Point

    let ca = area(c)
    let sa = area(s)
    let pa = area(p)

    // Circle area ≈ 12.566
    assert(ca > 12.0)
    assert(ca < 13.0)

    // Square area = 9.0
    assert(sa > 8.9)
    assert(sa < 9.1)

    // Point area = 0.0
    assert(pa > -0.1)
    assert(pa < 0.1)
