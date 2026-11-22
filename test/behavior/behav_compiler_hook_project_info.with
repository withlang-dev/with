//! expect-stdout: ok

use std.compiler

@[compiler_hook(after_typecheck)]
fn inspect_project(project: ProjectInfo):
    let functions = project.functions()
    var saw_hook = false
    var saw_main = false
    for f in functions:
        if f.name == "inspect_project":
            saw_hook = true
        if f.name == "main":
            saw_main = true
    assert(saw_hook)
    assert(saw_main)

fn main:
    print("ok")
