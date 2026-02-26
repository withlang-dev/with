// Test: trait bounds checking at call sites
trait Display =
    fn show(self: Self) -> i32

trait Eq =
    fn eq(self: Self, other: Self) -> bool

type Point = {
    x: i32,
    y: i32,
}

impl Display for Point =
    fn show(self: Point) -> i32: self.x + self.y

impl Eq for Point =
    fn eq(self: Point, other: Point) -> bool: self.x == other.x and self.y == other.y

// Single trait bound
fn display[T: Display](val: T) -> i32:
    val.show()

// Multiple bounds
fn compare_and_show[T: Display + Eq](a: T, b: T) -> i32:
    if a.eq(b) then a.show() else a.show() + b.show()

fn main -> i32:
    let p = Point { x: 1, y: 2 }
    let q = Point { x: 3, y: 4 }

    let r1 = display(p)
    assert(r1 == 3)

    let r2 = compare_and_show(p, q)
    assert(r2 == 10)

    println("all trait bounds check tests passed")
