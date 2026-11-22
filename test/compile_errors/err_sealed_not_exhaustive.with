//! expect-error: non-exhaustive match on sealed trait: missing implementor 'Rect'

// #1860: a `@[sealed]` trait's implementor set is the match's domain; a
// missing implementor is the ordinary non-exhaustive error.

@[sealed]
trait Shape:
    fn area(self: &Self) -> i32
type Circle { radius: i32 }
type Rect { width: i32, height: i32 }
impl Shape for Circle:
    fn area(self: &Self) -> i32: 0
impl Shape for Rect:
    fn area(self: &Self) -> i32: 0

fn describe(s: &dyn Shape) -> i32:
    match s:
        c: Circle => c.radius
