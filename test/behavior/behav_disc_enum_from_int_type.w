//! expect-stdout: green
//! expect-stdout: red blue none green
//! expect-stdout: blue
//! expect-stdout: true true
//! expect-stdout: big
//! expect-stdout: 200
//! expect-stdout: tiny none
//! expect-stdout: neg
//! expect-stdout: two
//! expect-stdout: blue

// #1453 (§4.4a): `Type.from_int(n)` is an `Option[Type]` —
// `Color.from_int(2)` is `Some(Color.Green)`. It was typed `Option[i32]`
// (the repr's Option): an annotated binding, a fn return and a variant
// pattern on the payload were type errors. Matrix: annotated / inferred /
// returned / `if let` / `??` / is_some; reprs i32, u32 (3e9), u8, i64
// (negative), and an inferred-i32 enum; a value matching no discriminant.

enum Color: i32:
    Red = 1
    Green = 2
    Blue = 4

impl Copy for Color

enum K: u32:
    A = 1
    Big = 3000000000

enum Tiny: u8:
    Lo = 3
    Hi = 200

enum Wide: i64:
    Neg = -5000000000
    Pos = 5000000000

enum Plain:
    One
    Two

fn color_name(c: Color) -> str:
    match c:
        .Red => "red".clone()
        .Green => "green".clone()
        .Blue => "blue".clone()

fn show(o: Option[Color]) -> str:
    match o:
        Some(c) => color_name(c)
        None => "none".clone()

fn decode(n: i32) -> Option[Color]: Color.from_int(n)

fn main:
    let c: Option[Color] = Color.from_int(2)
    match c:
        Some(.Green) => print("green")
        _ => print("other")
    print(f"{show(Color.from_int(1))} {show(Color.from_int(4))} {show(Color.from_int(3))} {show(decode(2))}")
    let inferred = Color.from_int(4)
    if let Some(col) = inferred:
        print(color_name(col))
    print(f"{Color.from_int(4).is_some()} {Color.from_int(99).is_none()}")
    match K.from_int(3000000000):
        Some(.Big) => print("big")
        Some(.A) => print("a")
        None => print("none")
    match Tiny.from_int(200):
        Some(t) => print(t as u8)
        None => print("none")
    match Tiny.from_int(4):
        Some(t) => print(t as u8)
        None => print("tiny none")
    match Wide.from_int(-5000000000):
        Some(.Neg) => print("neg")
        _ => print("other")
    match Plain.from_int(1):
        Some(.Two) => print("two")
        _ => print("other")
    let back = Color.from_int(Color.Blue as i32) ?? Color.Red
    print(color_name(back))
