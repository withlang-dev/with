//! expect-stdout: 7
//! expect-stdout: none
//! expect-stdout: 3
// §17 (#2950): a variant with a payload is a comptime value, and a bare
// variant of a payload-carrying enum too.
enum Shape:
    Dot
    Circle(i32)
    Rect(i32, i32)
const CIRCLE: Shape = .Circle(7)
const DOT: Shape = .Dot
const RECT: Shape = .Rect(1, 3)
const AREA: i32 = comptime match CIRCLE:
    .Dot => 0
    .Circle(r) => r
    .Rect(w, h) => w * h
const NAME: str = comptime match DOT:
    .Dot => "none"
    .Circle(r) => "circle"
    .Rect(w, h) => "rect"
const RECT_AREA: i32 = comptime match RECT:
    .Dot => 0
    .Circle(r) => r
    .Rect(w, h) => w * h
fn main:
    print(AREA)
    print(NAME)
    print(RECT_AREA)
