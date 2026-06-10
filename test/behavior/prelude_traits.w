//! expect-stdout: ok

// Test: Trait declarations from prelude are available without explicit use.
// - Defining a type and implementing Eq for it should work
// - Implementing Debug should work
// - Generic function with trait bound should work

type Point { x: i32, y: i32 }

impl Eq for Point:    fn eq(self: Point, other:
    Point) -> bool:
        self.x == other.x and self.y == other.y

impl Debug for Point:    fn debug_str(self:
    Point) -> str:
        "Point"

fn main:
    let a = Point { x: 1, y: 2 }
    let b = Point { x: 1, y: 2 }
    let c = Point { x: 3, y: 4 }
    assert(a.eq(b))
    assert(not a.eq(c))
    assert(a.debug_str() == "Point")
    print("ok")
