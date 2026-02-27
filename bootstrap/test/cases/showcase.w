// Showcase: demonstrates many With language features

// --- Struct with methods ---
type Vec2 = {
    x: i32,
    y: i32,
}

impl Vec2 =
    fn new(x: i32, y: i32) -> Vec2:
        Vec2 { x: x, y: y }

    fn add(self: Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }

    fn dot(self: Vec2, other: Vec2) -> i32:
        self.x * other.x + self.y * other.y

    fn scale(self: Vec2, s: i32) -> Vec2:
        Vec2 { x: self.x * s, y: self.y * s }

// --- Traits ---
trait Measurable =
    fn measure(self: Self) -> i32

impl Measurable for Vec2 =
    fn measure(self: Vec2) -> i32:
        self.x * self.x + self.y * self.y

// --- Generic function with trait bounds ---
fn get_measure[T: Measurable](x: T) -> i32:
    x.measure()

// --- Enum with match ---
type Shape = Circle(i32) | Rectangle(i32)

fn area(s: Shape) -> i32:
    match s
        Circle(r) -> r * r * 3
        Rectangle(side) -> side * side

// --- Higher-order functions ---
fn apply(x: i32, f: fn(i32) -> i32) -> i32:
    f(x)

fn triple(x: i32) -> i32: x * 3

// --- Main ---
fn main -> i32:
    let a = Vec2.new(3, 4)
    let b = Vec2.new(1, 2)
    let c = a + b
    assert(c.x == 4)
    assert(c.y == 6)
    let d = a.dot(b)
    assert(d == 11)
    let m = get_measure(a)
    assert(m == 25)
    let circle = Circle(5)
    let rect = Rectangle(4)
    assert(area(circle) == 75)
    assert(area(rect) == 16)
    assert(apply(7, triple) == 21)
    let (x, y) = (100, 200)
    assert(x == 100)
    assert(y == 200)
    let arr = [1, 2, 3, 4, 5]
    var sum: i32 = 0
    for v in arr:
        sum += v
    assert(sum == 15)
    let scaled = { a with x: 10 }
    assert(scaled.x == 10)
    assert(scaled.y == 4)
    println(c)
