//! expect-stdout: ok
// libpng declares every function through a function-like macro whose last
// argument is the attribute macro: `PNG_INTERNAL_FUNCTION(png_voidp,
// png_malloc_base, (…), PNG_ALLOCATED)`, with PNG_ALLOCATED
// `__attribute__((__malloc__))` defined in another header. The declaration's
// extent then starts in one file and ends in another and its tokens read
// nothing: libpng's report showed no attribute on any of its 256 functions,
// and png_create_info_struct stayed raw. The attribute is the function's in
// Clang's AST; it is read from there.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_macro_arg_attr_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let conf = "#define T_ALLOCATED __attribute__((__malloc__))\n#define T_FN(type, name, args, attributes) attributes type name args\n#define T_EXPORT(type, name, args, attributes) T_FN(type, name, args, attributes)\n"
    let header = "#include <stddef.h>\n#include \"tconf.h\"\ntypedef struct Thing Thing;\nT_EXPORT(Thing *, thing_make, (void), T_ALLOCATED);\nvoid thing_free(Thing *t);\nT_EXPORT(void *, thing_alloc, (size_t n), T_ALLOCATED);\n"
    for dir in [dep ++ "/include", src]:
        assert(write_file(dir ++ "/tconf.h", conf) == 0)
        assert(write_file(dir ++ "/thing.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include \"thing.h\"\nstruct Thing { int n; };\nstatic void *(*alloc_hook)(size_t);\n"
    unit = unit ++ "T_FN(void *, thing_alloc, (size_t n), T_ALLOCATED) { if (alloc_hook) return alloc_hook(n); return malloc(n); }\n"
    unit = unit ++ "Thing *thing_make(void) { return (Thing *)thing_alloc(sizeof(Thing)); }\n"
    unit = unit ++ "void thing_free(Thing *t) { free(t); }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    var make_line = ""
    var alloc_line = ""
    for line in report.split("\n"):
        if line.starts_with("  thing_make:"): make_line = line.to_owned()
        if line.starts_with("  thing_alloc:"): alloc_line = line.to_owned()
    let ok = alloc_line.contains("__malloc__") and make_line.contains("owned producer of Thing")
    if not ok: print(report)
    assert(alloc_line.contains("__malloc__"), alloc_line)
    assert(make_line.contains("owned producer of Thing"), make_line)
    print("ok")
