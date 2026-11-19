//! expect-stdout: 4
//! expect-stdout: 5
//! expect-stdout: sq

// D223 (§9.3a): `Type.name` is found as at a call: a variant before a
// method of the same name. `Shape.Square` is the variant; the method is
// reached on a value.
enum Shape:
    Circle(r: i32)
    Square
impl Shape:
    fn Square() -> i32: 4
    fn Circle() -> i32: 5
fn main:
    let s = Shape.Square
    print(s.Square())
    let c = Shape.Circle(2)
    print(c.Circle())
    match s:
        .Square => print("sq")
        .Circle(r) => print(r)
