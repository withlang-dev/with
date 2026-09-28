//! expect-check-fail: is not @[sealed], so its implementors are open

// #1860: a non-sealed trait's implementor set is open, so a match on its
// object needs a `_` arm.

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
        r: Rect => r.width
