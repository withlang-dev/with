//! expect-stdout: 5 42
// #628: a local/param whose name matches a visible type name must win in
// value/receiver position. Here `code` is both a type and a parameter; the
// receiver `code` in `code.len()` is the str parameter, not the type.
type code { x: i32 }

fn describe(code: str) -> i64:
    code.len()

fn add_one(code: i32) -> i32:
    code + 1

fn main:
    print(f"{describe(\"hello\")} {add_one(41)}")
