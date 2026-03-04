type Shape = Circle(i32) | Rect(i32)

type Point = { x: i32, y: i32 }

fn origin -> Point:
    Point { x: 0, y: 0 }
