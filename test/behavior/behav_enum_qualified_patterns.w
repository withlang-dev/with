//! expect-stdout: ok

enum Shape:
    Circle(i32)
    Rect(i32, i32)
    Empty

fn area(shape: Shape) -> i32:
    match shape
        Shape.Circle(r) => r * r
        Shape.Rect(w, h) => w * h
        Shape.Empty => 0

fn test_match:
    assert(area(Shape.Circle(3)) == 9)
    assert(area(Shape.Rect(2, 5)) == 10)
    assert(area(Shape.Empty) == 0)

fn test_if_let:
    if let Shape.Rect(w, h) = Shape.Rect(4, 6):
        assert(w == 4)
        assert(h == 6)
    else:
        assert(false)

fn nested_tag(shape: Shape) -> i32:
    match shape
        Shape.Circle(r) => match Shape.Circle(r + 1)
            Shape.Circle(inner) => inner
            Shape.Rect(_, _) => 0
            Shape.Empty => 0
        Shape.Rect(_, _) => 10
        Shape.Empty => 20

fn test_nested_match:
    assert(nested_tag(Shape.Circle(7)) == 8)
    assert(nested_tag(Shape.Rect(1, 2)) == 10)
    assert(nested_tag(Shape.Empty) == 20)

fn main:
    test_match()
    test_if_let()
    test_nested_match()
    println("ok")
