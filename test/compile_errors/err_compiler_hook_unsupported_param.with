//! expect-error: compiler_hook parameter must be ProjectInfo, Diagnostics, or SourceEmitter from std.compiler

use std.compiler

@[compiler_hook(after_typecheck)]
fn invalid_hook(value: i32):
    let _ = value

fn main:
    print("unreachable")
