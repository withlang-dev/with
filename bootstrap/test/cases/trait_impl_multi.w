// Test: multiple trait impls for same struct
trait Describable =
    fn describe(self: Self) -> i32

trait Measurable =
    fn measure(self: Self) -> i32

trait Comparable =
    fn compare(self: Self, other: i32) -> bool

type Box = {
    width: i32,
    height: i32
}

impl Describable for Box =
    fn describe(self: Box) -> i32:
        self.width + self.height

impl Measurable for Box =
    fn measure(self: Box) -> i32:
        self.width * self.height

impl Comparable for Box =
    fn compare(self: Box, other: i32) -> bool:
        self.width * self.height > other

fn main -> i32:
    let b = Box { width: 6, height: 7 }
    assert(b.describe() == 13)
    assert(b.measure() == 42)
    assert(b.compare(41))
    assert(not b.compare(42))
