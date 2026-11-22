//! expect-check-fail: explicit type arguments are not written at call sites

// #598 (ruled: no turbofish): explicit type args on a free generic fn get a
// teaching diagnostic, not "value is not callable".

use std.builtins.print_i32
fn id[T](x: T) -> T:
    x

fn main:
    let y = id[i32](42)
    print_i32(y)
