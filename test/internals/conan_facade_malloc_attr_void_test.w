//! expect-stdout: ok
// libpng's png_create_info_struct returns `(png_inforp)png_malloc_base(…)`,
// and png_malloc_base returns `void *` under `__attribute__((malloc))`
// (PNG_ALLOCATED). The annotation was honoured only on a function returning
// a record, so the producer read 'png_malloc_base is unproven ()': raw, with
// an empty reason. A package function the library annotates malloc is an
// allocator call, as malloc is.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_malloc_attr_void_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Thing Thing;\ntypedef struct Other Other;\nThing *thing_make(void);\nvoid thing_free(Thing *t);\nOther *other_make(void);\nvoid other_free(Other *o);\n"
    assert(write_file(dep ++ "/include/thing.h", header) == 0)
    assert(write_file(src ++ "/thing.h", header) == 0)
    // libpng's shape: the attribute through an object-like macro, in GCC's
    // reserved spelling, before the return type (PNG_ALLOCATED); and the
    // plain spelling after the declarator.
    var unit = "#include <stdlib.h>\n#include \"thing.h\"\n#define THING_ALLOCATED __attribute__((__malloc__))\nstruct Thing { int n; };\nstruct Other { int n; };\nstatic void *(*alloc_hook)(size_t);\n"
    unit = unit ++ "THING_ALLOCATED void *thing_alloc(size_t n);\n"
    unit = unit ++ "THING_ALLOCATED void *thing_alloc(size_t n) { if (alloc_hook) return alloc_hook(n); return malloc(n); }\n"
    unit = unit ++ "void *other_alloc(size_t n) __attribute__((malloc));\n"
    unit = unit ++ "void *other_alloc(size_t n) { if (alloc_hook) return alloc_hook(n); return malloc(n); }\n"
    unit = unit ++ "Thing *thing_make(void) { return (Thing *)thing_alloc(sizeof(Thing)); }\n"
    unit = unit ++ "void thing_free(Thing *t) { free(t); }\n"
    unit = unit ++ "Other *other_make(void) { return (Other *)other_alloc(sizeof(Other)); }\n"
    unit = unit ++ "void other_free(Other *o) { free(o); }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    var make_line = ""
    var other_line = ""
    for line in report.split("\n"):
        if line.starts_with("  thing_make:"): make_line = line.to_owned()
        if line.starts_with("  other_make:"): other_line = line.to_owned()
    let ok = make_line.contains("owned producer of Thing") and other_line.contains("owned producer of Other") and not report.contains("unproven ()")
    if not ok: print(report)
    assert(make_line.contains("owned producer of Thing"), make_line)
    assert(other_line.contains("owned producer of Other"), other_line)
    assert(not report.contains("unproven ()"))
    print("ok")
