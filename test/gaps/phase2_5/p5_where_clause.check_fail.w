// Phase 5: where clauses on generic functions
trait Describable =
    fn describe(self: Self) -> i32

type Point = { x: i32, y: i32 }

impl Describable for Point =
    fn describe(self: Point) -> i32: self.x + self.y

fn summarize[T](item: T) -> i32 where T: Describable:
    item.describe()

fn main -> i32:
    let p = Point { x: 19, y: 23 }
    if summarize(p) == 42 then 0 else 1
