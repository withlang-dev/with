//! expect-stdout: 1.5 9
//! expect-stdout: ab-cd 5
//! expect-stdout: 200 1

// #2043 (D65): codegen emits the types and constants Sema decided — a
// transmute target in each specialization of one generic function, a module
// string constant built from another, a discriminant enum's repr — and never
// resolves the AST itself (audit:codegen counts any that it does).
fn same[T](x: T) -> T: unsafe { transmute[T](x) }

let PREFIX = "ab"
let LABEL = PREFIX ++ "-cd"

enum Level: u8:
    Low = 1
    High = 200

fn main:
    print(f"{same(1.5 as f32)} {same(9 as i64)}")
    print(f"{LABEL} {LABEL.len()}")
    print(f"{Level.High as i32} {Level.Low as i32}")
