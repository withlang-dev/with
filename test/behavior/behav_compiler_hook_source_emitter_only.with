//! expect-stdout: ok

use std.compiler

@[compiler_hook(after_typecheck)]
fn generate(source: SourceEmitter):
    source.emit_source("fn generated_value -> i32:\n    42\n")

fn main:
    print("ok")
