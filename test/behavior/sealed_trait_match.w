//! expect-stdout: ok
@[sealed]
trait Shape =
    fn area(self: Self) -> i32

type Circle { radius: i32 }
type Rect { width: i32, height: i32 }

impl Shape for Circle =
    fn area(self: Circle) -> i32: self.radius * self.radius * 3
impl Shape for Rect =
    fn area(self: Rect) -> i32: self.width * self.height

fn describe(s: dyn Shape) -> i32:
    match s:
        c: Circle => c.radius
        r: Rect => r.width + r.height

fn main:
    let c = Circle { radius: 5 }
    let r = Rect { width: 3, height: 4 }
    assert(describe(c) == 5)
    assert(describe(r) == 7)
    print("ok")
