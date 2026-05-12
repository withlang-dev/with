//! expect-stdout: ok

use std.compiler

@[compiler_hook(after_typecheck)]
fn generate_source(project: ProjectInfo):
    let _ = project
    compiler.emit_source("fn generated_from_hook -> i32:\n    7\n")

fn main:
    print("ok")
