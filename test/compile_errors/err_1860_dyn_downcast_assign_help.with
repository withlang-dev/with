//! expect-check-fail: mutate through the trait's `mut fn` methods on the object's place

// #1860: the downcast binding is a view of the object; With has no `&mut T`
// (§15.1), so an assignment through it names where mutation goes.

@[sealed]
trait Shape:
    fn area(self: &Self) -> i32
type Circle { radius: i32 }
type Rect { width: i32, height: i32 }
impl Shape for Circle:
    fn area(self: &Self) -> i32: 0
impl Shape for Rect:
    fn area(self: &Self) -> i32: 0

fn grow(s: &dyn Shape):
    match s:
        c: Circle => c.radius = 9
        r: Rect => r.width = 9
