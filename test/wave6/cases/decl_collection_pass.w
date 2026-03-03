// Wave 6 unit test: declaration collection
// Covers: fn, type, let, extern, trait, impl

extern fn int_to_string(n: i32) -> str

type Point = {
    x: i32,
    y: i32,
}

trait Describe =
    fn describe(self: Self) -> str

impl Describe for Point =
    fn describe(self: Point) -> str:
        int_to_string(self.x)

let ORIGIN: Point = Point { x: 0, y: 0 }

fn make_point(x: i32, y: i32) -> Point:
    Point { x, y }

fn main -> i32:
    let p = make_point(1, 2)
    p.x
