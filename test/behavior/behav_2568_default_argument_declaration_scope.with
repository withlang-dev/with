//! expect-stdout: true
//! expect-stdout: 3

// #2568: a default argument resolves in its declaration's module. This
// program's own `src` never captures std's `panic(loc: &str = src())`.
use std.builtins.print_bool
fn src() -> i32: 3
fn main:
    print_bool(true)
    print(f"{src()}")
