//! expect-error: return type mismatch

use std.compiler

@[compiler_hook(after_typecheck)]
fn generate_bad_source(project: ProjectInfo):
    let _ = project
    compiler.emit_source("fn generated_bad -> i32:\n    \"bad\"\n")

fn main:
    print("ok")
