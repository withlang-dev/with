//! expect-stdout: ok
// #3195: a destroyer that frees its parameter through a local that walks a
// chain (`cur = t; while (cur) { next = cur->next; free(cur); cur = next; }`,
// cJSON_Delete) destroys the parameter: the first iteration frees it. The
// same with a for statement whose increment advances the local. A body
// that advances first and frees after (`cur = cur->next; free(cur)`) frees
// no parameter and stays as it was.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_walking_destroyer_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Thing Thing;\ntypedef struct Other Other;\nThing *thing_make(int n);\nvoid thing_free(Thing *t);\nvoid thing_free_for(Thing *t);\nOther *other_make(void);\nvoid other_skip_first(Other *o);\n"
    assert(write_file(dep ++ "/include/thing.h", header) == 0)
    assert(write_file(src ++ "/thing.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include \"thing.h\"\nstruct Thing { int n; struct Thing *next; };\nstruct Other { struct Other *next; };\n"
    unit = unit ++ "Thing *thing_make(int n) { Thing *t = (Thing *)malloc(sizeof(Thing)); if (!t) return NULL; t->n = n; t->next = NULL; return t; }\n"
    unit = unit ++ "void thing_free(Thing *t) { Thing *cur = t; while (cur) { Thing *next = cur->next; free(cur); cur = next; } }\n"
    unit = unit ++ "void thing_free_for(Thing *t) { Thing *next; for (Thing *cur = t; cur; cur = next) { next = cur->next; free(cur); } }\n"
    unit = unit ++ "Other *other_make(void) { return (Other *)malloc(sizeof(Other)); }\n"
    unit = unit ++ "void other_skip_first(Other *o) { Other *cur = o; cur = cur->next; free(cur); }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    var make_line = ""
    var free_line = ""
    var free_for_line = ""
    var skip_line = ""
    for line in report.split("\n"):
        if line.starts_with("  thing_make:"): make_line = line.to_owned()
        if line.starts_with("  thing_free:"): free_line = line.to_owned()
        if line.starts_with("  thing_free_for:"): free_for_line = line.to_owned()
        if line.starts_with("  other_skip_first:"): skip_line = line.to_owned()
    // Two unary destroyers of Thing leave the drop to a registry fact, by
    // design; the proof of the producer itself is what this test checks.
    let ok = make_line.contains("fresh allocation never retained") and free_line.contains("destroyer") and free_for_line.contains("destroyer") and not skip_line.contains("destroyer")
    if not ok: print(report)
    assert(make_line.contains("fresh allocation never retained"), make_line)
    assert(free_line.contains("destroyer"), free_line)
    assert(free_for_line.contains("destroyer"), free_for_line)
    assert(not skip_line.contains("destroyer"), skip_line)
    print("ok")
