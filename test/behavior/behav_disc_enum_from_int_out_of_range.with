//! expect-stdout: none
//! expect-stdout: none
//! expect-stdout: none
//! expect-stdout: 200
//! expect-stdout: a

// #1499 (§4.4a): `Type.from_int(n)` returns `.None` for an integer that is
// no discriminant — including one outside the repr's range that shares its
// low bits with one. The argument was narrowed to the repr before the
// comparison, so 456, 2^32 + 1 and -56 each matched.
enum Tiny: u8:
    Lo = 3
    Hi = 200

enum K: i32:
    A = 1

fn show_tiny(o: Option[Tiny]):
    match o:
        Some(t) => print(t as u8)
        None => print("none")

fn main:
    let n: i32 = 456
    show_tiny(Tiny.from_int(n))
    let m: i64 = 4294967297
    match K.from_int(m):
        Some(.A) => print("a")
        None => print("none")
    let neg: i32 = -56
    show_tiny(Tiny.from_int(neg))
    let hi: u8 = 200
    show_tiny(Tiny.from_int(hi))
    match K.from_int(1):
        Some(.A) => print("a")
        None => print("none")
