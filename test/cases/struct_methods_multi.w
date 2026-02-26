type Rect = { w: i32, h: i32 }

impl Rect =
    fn area(self: &Rect) -> i32: self.w * self.h
    fn perimeter(self: &Rect) -> i32: 2 * (self.w + self.h)
    fn is_square(self: &Rect) -> bool: self.w == self.h

fn main -> i32:
    let r = Rect { w: 4, h: 6 }
    println(r.area())
    println(r.perimeter())
    println(r.is_square())
    let s = Rect { w: 5, h: 5 }
    println(s.is_square())
