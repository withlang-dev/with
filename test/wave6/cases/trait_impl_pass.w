// Wave 6 unit test: trait declarations and impls
// Covers: trait, impl, trait method calls

trait Area =
    fn area(self: Self) -> i32

type Square = {
    side: i32,
}

type Rect = {
    width: i32,
    height: i32,
}

impl Area for Square =
    fn area(self: Square) -> i32:
        self.side * self.side

impl Area for Rect =
    fn area(self: Rect) -> i32:
        self.width * self.height

fn main -> i32:
    let s = Square { side: 4 }
    let r = Rect { width: 3, height: 5 }
    let sa = s.area()
    let ra = r.area()
    sa + ra
