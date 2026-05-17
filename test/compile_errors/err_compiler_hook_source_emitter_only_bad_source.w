//! expect-error: return type mismatch

use std.compiler

@[compiler_hook(after_typecheck)]
fn generate(source: SourceEmitter):
    source.emit_source("fn generated_bad -> i32:\n    \"bad\"\n")

fn main:
    print("ok")
