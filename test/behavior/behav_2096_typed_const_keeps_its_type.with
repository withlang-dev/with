//! expect-stdout: 12
// #2096: a typed constant keeps its declared type (`WIDE` stays i64); a
// narrower demand converts it with a range check (D183), it never retypes it.
const WIDE: i64 = 12
fn main:
    let z: i32 = WIDE
    print(f"{z}")
