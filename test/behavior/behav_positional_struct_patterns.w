//! expect-stdout: ok

type Point {
    x: i32,
    y: i32,
}

type Line {
    start: Point,
    end: Point,
}

enum Shape:
    Dot(Point)
    Label(str)

fn test_match_struct_fields:
    let p = Point { x: 3, y: 4 }
    match p:
        Point(x, y) => assert(x + y == 7)

fn test_nested_struct_fields:
    let line = Line { start: Point { x: 1, y: 2 }, end: Point { x: 5, y: 8 } }
    match line:
        Line(Point(sx, 2), Point(ex, ey)) =>
            assert(sx == 1)
            assert(ex + ey == 13)
        _ => assert(false)

fn score_shape(shape: Shape) -> i32:
    match shape:
        .Dot(Point(0, y)) => y
        .Dot(Point(x, y)) => x + y
        .Label(_) => -1

fn main:
    test_match_struct_fields()
    test_nested_struct_fields()
    assert(score_shape(Shape.Dot(Point { x: 0, y: 9 })) == 9)
    assert(score_shape(Shape.Dot(Point { x: 2, y: 5 })) == 7)
    assert(score_shape(Shape.Label("p")) == -1)
    print("ok")
