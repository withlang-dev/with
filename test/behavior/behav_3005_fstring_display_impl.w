//! expect-stdout: (1, 2)
//! expect-stdout: p = (1, 2)
//! expect-stdout: Point { x: 1, y: 2 }
//! expect-stdout: [  (1, 2)]
//! expect-stdout: at (1, 2)
// #3005 (§15.4, D193): `{p}` displays a type through its `impl Display`, as
// `print(p)` does; `:?` stays the Debug form; a width pads the display
// text. A struct with no Display impl is still refused
// (err_3005_struct_without_display.w).
pub type Point { x: i32, y: i32 }

impl Display for Point:
    fn to_str() -> str: f"({self.x}, {self.y})"

fn where_is(p: &Point) -> str: f"at {p}"

fn main:
    let p = Point { x: 1, y: 2 }
    print(p)
    print(f"p = {p}")
    print(f"{p:?}")
    print(f"[{p:>8}]")
    print(where_is(&p))
