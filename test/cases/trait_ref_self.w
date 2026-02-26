// Test &Self in trait method declarations and impl blocks
type Point = { x: i32, y: i32 }

trait Summable =
    fn total(self: &Self) -> i32

impl Summable for Point =
    fn total(self: &Point) -> i32: self.x + self.y

fn main -> i32:
    let p = Point { x: 3, y: 4 }
    let s = p.total()
    println(s)
