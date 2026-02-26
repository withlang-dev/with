type Point = {
    x: i32,
    y: i32
}

impl Point =
    fn sum(self: Point) -> i32:
        self.x + self.y

    fn scale(self: Point, factor: i32) -> i32:
        self.x * factor + self.y * factor

fn main -> i32:
    let p = Point { x: 10, y: 11 }
    let s = p.sum()
    let t = p.scale(2)
    assert(t == 42)
