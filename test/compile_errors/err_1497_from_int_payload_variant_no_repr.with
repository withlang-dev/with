//! expect-check-fail: `Shape.from_int` does not exist: variant `Circle` carries a payload

// D71 / §4.4a (#1497): on an enum with a payload variant a `from_int` call is
// a compile error naming that variant — with no representation type too.
// It was "unknown method 'from_int' for type 'Shape'", which names no
// variant and reads as a missing import or a typo.

enum Shape:
    Dot
    Circle(f64)
    Square(f64)

fn main:
    let o = Shape.from_int(0)
