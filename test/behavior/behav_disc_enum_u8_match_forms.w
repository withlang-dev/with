//! expect-stdout: 11 10 20 30
//! expect-stdout: 1 2 3 4
//! expect-stdout: 7 8 9
//! expect-stdout: if-let hi
//! expect-stdout: quit 0
//! expect-stdout: move 3 4 1
//! expect-stdout: write hi 2

// #1444: guards, tuple subjects, Option payloads, if-let and a payload
// discriminant enum over a u8 repr (the tag is the u8 in `{ u8, payload }`).
// Before the fix every u8 match here read garbage and the program trapped.

enum Kind: u8:
    Red = 1
    Blue = 2
    Hi = 200

impl Copy for Kind

enum Msg: u8:
    Quit = 0
    Move(i32, i32) = 1
    Write(str) = 2

fn guarded(k: Kind, n: i32) -> i32:
    match k:
        .Red if n > 5 => 11
        .Red => 10
        .Blue => 20
        .Hi => 30

fn pair(a: Kind, b: Kind) -> i32:
    match (a, b):
        (.Red, .Red) => 1
        (.Hi, .Blue) => 2
        (.Blue, _) => 3
        _ => 4

fn opt(o: Option[Kind]) -> i32:
    match o:
        Some(.Hi) => 7
        Some(_) => 8
        None => 9

fn describe(m: &Msg) -> str:
    match m:
        .Quit => "quit".clone()
        .Move(x, y) => f"move {x} {y}"
        .Write(s) => f"write {s}"

fn code(m: &Msg) -> i32:
    match m:
        .Quit => 0
        .Move(_, _) => 1
        .Write(_) => 2

fn main:
    print(f"{guarded(Kind.Red, 9)} {guarded(Kind.Red, 1)} {guarded(Kind.Blue, 0)} {guarded(Kind.Hi, 0)}")
    print(f"{pair(Kind.Red, Kind.Red)} {pair(Kind.Hi, Kind.Blue)} {pair(Kind.Blue, Kind.Hi)} {pair(Kind.Hi, Kind.Hi)}")
    print(f"{opt(Some(Kind.Hi))} {opt(Some(Kind.Blue))} {opt(None)}")
    if let .Hi = Kind.Hi:
        print("if-let hi")
    for m in [Msg.Quit, Msg.Move(3, 4), Msg.Write("hi".clone())]:
        print(f"{describe(m)} {code(m)}")
