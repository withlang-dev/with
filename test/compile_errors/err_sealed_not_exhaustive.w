//! expect-error: non-exhaustive
@[sealed]
trait Shape =
    fn area(self: &Self) -> i32
type Circle { radius: i32 }
type Rect { width: i32, height: i32 }
impl Shape for Circle =
    fn area(self: Circle) -> i32: 0
impl Shape for Rect =
    fn area(self: Rect) -> i32: 0

fn describe(s: dyn Shape) -> i32:
    match s:
        c: Circle => c.radius
