// Test: impl blocks with multiple methods and complex logic
type Rect = {
    x: i32,
    y: i32,
    w: i32,
    h: i32
}

impl Rect =
    fn new(x: i32, y: i32, w: i32, h: i32) -> Rect =
        Rect { x: x, y: y, w: w, h: h }

    fn area(self: Rect) -> i32 =
        self.w * self.h

    fn perimeter(self: Rect) -> i32 =
        2 * (self.w + self.h)

    fn contains_point(self: Rect, px: i32, py: i32) -> bool =
        px >= self.x and px < self.x + self.w and py >= self.y and py < self.y + self.h

    fn right(self: Rect) -> i32 =
        self.x + self.w

    fn bottom(self: Rect) -> i32 =
        self.y + self.h

    fn is_square(self: Rect) -> bool =
        self.w == self.h

type Counter = {
    value: i32,
    step: i32,
    max_val: i32
}

impl Counter =
    fn new(step: i32, max_val: i32) -> Counter =
        Counter { value: 0, step: step, max_val: max_val }

    fn current(self: Counter) -> i32 =
        self.value

    fn is_done(self: Counter) -> bool =
        self.value >= self.max_val

fn main() -> i32 =
    // Rect tests
    let r = Rect.new(10, 20, 30, 40)
    assert(r.area() == 1200)
    assert(r.perimeter() == 140)
    assert(r.right() == 40)
    assert(r.bottom() == 60)
    assert(not r.is_square())

    // Contains point tests
    assert(r.contains_point(15, 25))
    assert(r.contains_point(10, 20))
    assert(not r.contains_point(5, 25))
    assert(not r.contains_point(15, 65))

    // Square detection
    let sq = Rect.new(0, 0, 10, 10)
    assert(sq.is_square())
    assert(sq.area() == 100)

    // Counter tests
    let c = Counter.new(5, 100)
    assert(c.current() == 0)
    assert(not c.is_done())

    // Record update to simulate stepping
    let c2 = { c with value: c.value + c.step }
    assert(c2.current() == 5)
    assert(not c2.is_done())

    let c3 = { c with value: 100 }
    assert(c3.is_done())

    println("all impl_methods_complex tests passed")
    0
