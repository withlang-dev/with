//! expect-error: public function missing docs

use std.compiler

@[compiler_hook(after_typecheck)]
fn lint_project(project: ProjectInfo):
    let functions = project.functions()
    for f in functions:
        if f.name == "missing_docs" and f.is_pub() and not f.has_docs():
            compiler.error(f.location(), "public function missing docs")

pub fn missing_docs -> i32:
    1
