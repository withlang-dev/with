//! expect-check-fail: `Msg.from_int` does not exist: variant `Move` carries a payload

// D71 / §4.4a (#1497): "`from_int` exists only on an enum whose variants are
// all unit variants. No value of the enum exists for a payload variant's
// discriminant alone, so on an enum with a payload variant a `from_int` call
// is a compile error naming that variant." It compiled and returned the
// repr's Option: `Msg.from_int(7)` was `Some(7)`, an `Option[i32]`.

enum Msg: i32:
    Quit = 0
    Move(i32, i32) = 7

fn main:
    let o = Msg.from_int(7)
    match o:
        Some(v) => print(v)
        None => print("none")
