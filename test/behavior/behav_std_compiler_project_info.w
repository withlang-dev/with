//! expect-stdout: ok

use std.compiler

fn main:
    let loc = SourceLocation.new("src/main.w", 10, 20)
    let fun = FunctionInfo.new("main", "run", true, false, 2, "i32", loc)
    let ty = TypeInfo.new("main", "Runner", true, true, "struct", loc)
    var project = ProjectInfo.new()
    project = project.add_module(ModuleInfo.new("main", "src/main.w"))
    project = project.add_function(fun)
    project = project.add_type(ty)

    let modules = project.modules()
    assert(modules.len() == 1)
    assert(modules.get(0).name == "main")

    let functions = project.functions()
    assert(functions.len() == 1)
    let f = functions.get(0)
    assert(f.name == "run")
    assert(f.is_pub())
    assert(not f.has_docs())
    assert(f.location().file == "src/main.w")
    assert(f.param_count == 2)

    let types = project.types()
    assert(types.len() == 1)
    let t = types.get(0)
    assert(t.name == "Runner")
    assert(t.is_pub())
    assert(t.has_docs())
    assert(t.kind == "struct")
    print("ok")

