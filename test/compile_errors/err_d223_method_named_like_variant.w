//! expect-check-fail: `Square` is a variant of `Shape` and cannot also be a method of it: `Shape.Square` would name either (§9.3a)

// D223 (§9.3a): `Type.name` names one thing.
enum Shape:
    Circle(r: i32)
    Square
impl Shape:
    fn Square() -> i32: 4
fn main: print(1)
