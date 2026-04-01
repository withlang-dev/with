//! expect-stdout: ok

// Local trait, foreign type (i32) — OK
trait Describable =
    fn describe(self: Self) -> str

impl Describable for i32 =
    fn describe(self: i32) -> str:
        "an integer"

// Foreign trait (Debug), local type — OK
type Point { x: i32, y: i32 }

impl Debug for Point =
    fn debug(self: Point) -> str:
        "Point"

fn main:
    print("ok")
