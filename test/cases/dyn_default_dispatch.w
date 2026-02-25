// Test: dyn dispatch can call a default trait method
trait Scoreable =
    fn score(self: Self) -> i32
    fn doubled(self: Self) -> i32 =
        self.score() * 2

type Point = {
    x: i32,
}

impl Scoreable for Point =
    fn score(self: Point) -> i32 = self.x

fn via_dyn(s: dyn Scoreable) -> i32 =
    s.doubled()

fn main() -> i32 =
    let p = Point { x: 21 }
    assert(via_dyn(p) == 42)
    0
