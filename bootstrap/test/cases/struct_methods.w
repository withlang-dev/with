// Test: struct with impl block methods
type Rect = {
    width: i32,
    height: i32
}

impl Rect =
    fn area(self: Rect) -> i32:
        self.width * self.height

    fn perimeter(self: Rect) -> i32:
        2 * (self.width + self.height)

    fn is_square(self: Rect) -> bool:
        self.width == self.height

    fn scale(self: Rect, factor: i32) -> Rect:
        Rect { width: self.width * factor, height: self.height * factor }

fn main -> i32:
    let r = Rect { width: 3, height: 4 }
    assert(r.area() == 12)
    assert(r.perimeter() == 14)
    assert(not r.is_square())

    let sq = Rect { width: 5, height: 5 }
    assert(sq.is_square())
    assert(sq.area() == 25)

    // method returning new struct
    let big = r.scale(2)
    assert(big.width == 6)
    assert(big.height == 8)
    assert(big.area() == 48)

    println("all struct methods tests passed")
