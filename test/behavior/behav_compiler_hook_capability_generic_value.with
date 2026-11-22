//! expect-stdout: ok

use std.compiler

fn pass_through[T](item: T) -> T:
    item

@[compiler_hook(after_typecheck)]
fn generate(source: SourceEmitter):
    let forwarded = pass_through(source)
    forwarded.emit_source("fn generated_from_generic -> i32:\n    11\n")

fn main:
    print("ok")
