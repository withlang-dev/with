//! expect-check-fail: downcasts a trait object through a reference; this subject is a `dyn` value

// #1860: the downcast pattern's subject is the object through a reference;
// a by-value dyn is not defined (#1852, #724).

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
    match *s:
        c: Circle => c.radius
        r: Rect => r.width
