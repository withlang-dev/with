//! expect-error: hook diagnostics only

use std.compiler

@[compiler_hook(after_typecheck)]
fn lint(diagnostics: Diagnostics):
    diagnostics.error(SourceLocation.new("", 0, 0), "hook diagnostics only")

fn main:
    print("unreachable")
