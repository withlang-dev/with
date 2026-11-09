//! expect-stdout: ok
// #3172: a public function that calls through a function-pointer field
// named like itself (SDL's dynapi: `SDL_X` returns `jump_table.SDL_X(...)`)
// was read as calling itself; the proof chased it into itself and gave up
// with an empty reason ("SDL_X is unproven (SDL_X is unproven ())"), 126
// functions in sdl. The call is through the field, and the report says so.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_jump_table_callee_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Thing Thing;\nThing *thing_make(void);\nvoid thing_free(Thing *t);\n"
    assert(write_file(dep ++ "/include/thing.h", header) == 0)
    assert(write_file(src ++ "/thing.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include \"thing.h\"\nstruct Thing { int n; };\n"
    unit = unit ++ "static Thing *thing_make_REAL(void) { return (Thing *)malloc(sizeof(Thing)); }\n"
    unit = unit ++ "static void thing_free_REAL(Thing *t) { free(t); }\n"
    unit = unit ++ "struct { Thing *(*thing_make)(void); void (*thing_free)(Thing *); } jump_table = { thing_make_REAL, thing_free_REAL };\n"
    unit = unit ++ "Thing *thing_make(void) { return jump_table.thing_make(); }\n"
    unit = unit ++ "void thing_free(Thing *t) { jump_table.thing_free(t); }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    var make_line = ""
    for line in report.split("\n"):
        if line.starts_with("  thing_make:"): make_line = line.to_owned()
    if make_line.len() == 0 or make_line.contains("thing_make is unproven") or not make_line.contains("function pointer field thing_make"):
        print(report)
    assert(make_line.len() > 0)
    assert(not make_line.contains("thing_make is unproven"))
    assert(make_line.contains("function pointer field thing_make"))
    print("ok")
