//! expect-stdout: 1 8 4 5000000000 2

// #990: emit-C gives a fieldless enum the width its declaration states.
// Every one was `int32_t`: a `u8` enum took four bytes in a struct and a
// discriminant above i32's range was truncated.
enum Small: u8:
    A = 1
    B = 2

enum Big: i64:
    X = 5000000000
    Y = 1

type Hold { s: Small, t: Small, u: Small, v: Small }

fn main:
    let b = Big.X
    let h = Hold { s: .A, t: .B, u: .A, v: .B }
    print(f"{sizeof[Small]()} {sizeof[Big]()} {sizeof[Hold]()} {b as i64} {h.v as u8}")
