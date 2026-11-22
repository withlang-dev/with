//! expect-stdout: ok
// #3174: a parameter passed through a function-pointer field (glfw's
// `_glfw.platform.setWindowTitle(window, title)`) was a sink to a function
// named like the field, which no unit defines: 996 functions in 15
// libraries read 'passed to a callee no unit defines'. The sink names the
// field, and the report says which function pointer the parameter went
// through; which function the field holds is a registry fact.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_dispatch_sink_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Thing Thing;\nvoid thing_set_title(Thing *t, const char *title);\nvoid thing_fail(Thing *t, const char *message);\n"
    assert(write_file(dep ++ "/include/thing.h", header) == 0)
    assert(write_file(src ++ "/thing.h", header) == 0)
    var unit = "#include \"thing.h\"\nstruct Thing { const char *title; };\n"
    unit = unit ++ "static void set_title_cocoa(Thing *t, const char *title) { t->title = title; }\n"
    unit = unit ++ "static struct { void (*set_title)(Thing *, const char *); void (*on_error)(Thing *, const char *); } platform = { set_title_cocoa, 0 };\n"
    unit = unit ++ "void thing_set_title(Thing *t, const char *title) { platform.set_title(t, title); }\n"
    // The explicit dereference (libpng's png_error:
    // `(*(png_ptr->error_fn))(png_ptr, message)`) has no callee name; its
    // arguments read as plainly "stored".
    unit = unit ++ "void thing_fail(Thing *t, const char *message) { if (platform.on_error) (*(platform.on_error))(t, message); }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    var line_said = ""
    var fail_said = ""
    for line in report.split("\n"):
        if line.starts_with("  thing_set_title:"): line_said = line.to_owned()
        if line.starts_with("  thing_fail:"): fail_said = line.to_owned()
    let ok = line_said.contains("through the function pointer field set_title") and not line_said.contains("no unit defines") and fail_said.contains("through the function pointer field on_error")
    if not ok: print(report)
    assert(fail_said.contains("through the function pointer field on_error"), fail_said)
    assert(line_said.contains("through the function pointer field set_title"), line_said)
    assert(not line_said.contains("no unit defines"), line_said)
    print("ok")
