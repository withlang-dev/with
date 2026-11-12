//! expect-stdout: ok
// D198: the facade imports each header by itself, so it presents only what
// a header that compiles on its own declares. raylib's rcamera.h uses
// raylib.h's types without including it, and qoaplay.c prototypes its
// functions in the source file: the draft described both, the facade's own
// `use c_import("rcamera.h")` failed ("unknown type name 'Vector3'"), and
// `with get` reported hundreds of functions presented over a facade no
// program could import. A function only such a header declares, or one
// prototyped only in a source file, is no facade item, and the report says so.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_importable_headers_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let base = "typedef struct box box;\nbox *box_new(void);\nvoid box_free(box *b);\n"
    let extra = "int box_weight(box *b);\n"
    assert(write_file(dep ++ "/include/base.h", base) == 0)
    assert(write_file(dep ++ "/include/extra.h", extra) == 0)
    assert(write_file(src ++ "/base.h", base) == 0)
    assert(write_file(src ++ "/extra.h", extra) == 0)
    assert(write_file(src ++ "/box.c", "#include <stdlib.h>\n#include \"base.h\"\n#include \"extra.h\"\nstruct box { int w; };\nint box_hidden(box *b);\nbox *box_new(void) { box *b = malloc(sizeof(box)); b->w = 3; return b; }\nvoid box_free(box *b) { free(b); }\nint box_weight(box *b) { return b->w; }\nint box_hidden(box *b) { return b->w + 1; }\n") == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c box.c\",\n  \"file\": \"box.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"box\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("box", "1.0", dep, src, build)
    let facade = read_file(dep ++ "/contract.w") ?? ""
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    let ok = facade.contains("use c_import(\"base.h\"") and facade.contains("from box_new") and not facade.contains("extra.h") and not facade.contains("box_weight") and not facade.contains("box_hidden") and report.contains("do not compile on their own") and report.contains("extra.h")
    if not ok:
        print(facade)
        print(report)
    assert(ok)
    print("ok")
