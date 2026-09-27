//! expect-stdout: 7 dot

// D71 / §4.4a (#1497): the compiler's `from_int` exists only on an enum whose
// variants are all unit variants. A `from_int` the program declares on an
// enum with a payload variant is an ordinary static method: the rule refuses
// the built-in conversion, not the program's own function.

enum Shape:
    Dot
    Circle(i32)

fn Shape.from_int(n: i32) -> Shape: if n == 0: Shape.Dot else: Shape.Circle(n)

fn describe(s: Shape) -> str:
    match s:
        Shape.Circle(r) => f"{r}"
        Shape.Dot => "dot"

fn main:
    print(f"{describe(Shape.from_int(7))} {describe(Shape.from_int(0))}")
