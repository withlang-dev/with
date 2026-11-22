//! expect-stdout: ok
// #3179: a producer that frees its fresh allocation on the error path
// (`if (!fill(t)) { thing_free(t); return NULL; }`, cJSON_Duplicate_rec)
// passed the local to a callee the proof read as retaining it, since the
// destroyer stores its parameter in a local while walking. A callee that
// destroys the argument keeps nothing of it: the producer is owned.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_error_path_free_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Thing Thing;\nThing *thing_make(int n);\nvoid thing_free(Thing *t);\n"
    assert(write_file(dep ++ "/include/thing.h", header) == 0)
    assert(write_file(src ++ "/thing.h", header) == 0)
    // The address of a field of the fresh local (`zero(&t->n)`) is not the
    // address of the local: the callee cannot replace or keep `t` (#3179).
    var unit = "#include <stdlib.h>\n#include \"thing.h\"\nstruct Thing { int n; };\n"
    unit = unit ++ "static void zero(int *p) { *p = 0; }\n"
    unit = unit ++ "static int fill(Thing *t, int n) { if (n < 0) return 0; t->n = n; return 1; }\n"
    unit = unit ++ "void thing_free(Thing *t) { free(t); }\n"
    unit = unit ++ "Thing *thing_make(int n) { Thing *t = (Thing *)malloc(sizeof(Thing)); if (!t) return NULL; zero(&t->n); if (!fill(t, n)) { thing_free(t); return NULL; } return t; }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    var make_line = ""
    for line in report.split("\n"):
        if line.starts_with("  thing_make:"): make_line = line.to_owned()
    if not make_line.contains("owned producer of Thing"):
        print(report)
    assert(make_line.contains("owned producer of Thing"), make_line)
    print("ok")
