//! expect-check-fail: cannot assign through a read-only place

@[sealed]
trait Shape:
    fn area(self: &Self) -> i32
type Circle { radius: i32 }
impl Shape for Circle:
    fn area(self: &Self) -> i32: self.radius

fn observe(s: &dyn Shape):
    match s:
        c: Circle => print(c.radius)

// This c is an ordinary reference parameter, not a downcast binding.
fn unrelated(c: &Circle):
    c.radius = 9

fn same_body(s: &dyn Shape, other: &Circle):
    match s:
        c: Circle => print(c.radius)
    // The match arm's c has left scope; this binding owns a new marker.
    let c = other
    c.radius = 9

fn main: print(0)
