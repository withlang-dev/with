//! expect-error: wrong argument type

// #1856 (§4.2.1: "Suffixed literals are explicit and do not participate in
// contextual retyping"): `Ok(1i32)` fixes `T = i32` hard; a later
// `Result[i64, str]` parameter is a mismatch.

fn wide(r: Result[i64, str]) -> i64: r ?? 0

fn main:
    let a = Ok(1i32)
    print(wide(a))
