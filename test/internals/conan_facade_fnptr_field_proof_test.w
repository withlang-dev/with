//! expect-stdout: ok
// D198 (#3206, Eric 2026-11-09): a call through a function-pointer field has
// a proven callee only when the field is written in exactly one place, that
// place names a package function, and the record never leaves what the
// drafter reads. Each condition, and what the report says when it fails
// (the line a registry fact's author reads):
//   one_show     one constant initializer naming a package function that
//                only reads: proven, and the wrapper presents as a lend
//   two_show     the same field written by two tables (glfw's cocoa and
//                null platforms): "written in 2 places"
//   zeroed_show  the table handed to memset: "passed to memset, which the
//                proofs cannot read"
//   cast_show    a pointer to the table converted to `char *`
//   user_show    a field only the caller ever fills: "never writes it"
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_fnptr_field_proof_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    var header = "typedef struct Thing Thing;\nThing *thing_new(void);\nvoid thing_free(Thing *t);\n"
    header = header ++ "struct UserOps { void (*show)(Thing *); };\n"
    for name in ["one", "two", "zeroed", "cast"]: header = header ++ "void " ++ name ++ "_show(Thing *t);\n"
    header = header ++ "void user_show(struct UserOps *ops, Thing *t);\n"
    assert(write_file(dep ++ "/include/thing.h", header) == 0)
    assert(write_file(src ++ "/thing.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include <string.h>\n#include \"thing.h\"\nstruct Thing { int n; };\n"
    unit = unit ++ "Thing *thing_new(void) { return (Thing *)malloc(sizeof(Thing)); }\nvoid thing_free(Thing *t) { free(t); }\n"
    unit = unit ++ "static int shown;\nstatic void show_a(Thing *t) { shown = t->n; }\nstatic void show_b(Thing *t) { shown = t->n + 1; }\n"
    unit = unit ++ "struct OneOps { void (*show)(Thing *); };\nstatic const struct OneOps one_ops = { show_a };\n"
    unit = unit ++ "void one_show(Thing *t) { one_ops.show(t); }\n"
    unit = unit ++ "struct TwoOps { void (*show)(Thing *); };\nstatic const struct TwoOps cocoa = { show_a };\nstatic const struct TwoOps null_platform = { .show = show_b };\nstatic struct TwoOps active;\n"
    unit = unit ++ "void two_show(Thing *t) { active = t->n ? cocoa : null_platform; active.show(t); }\n"
    unit = unit ++ "struct ZeroedOps { void (*show)(Thing *); };\nstatic struct ZeroedOps zeroed_ops = { show_a };\n"
    unit = unit ++ "void zeroed_show(Thing *t) { if (!t) memset(&zeroed_ops, 0, sizeof zeroed_ops); else zeroed_ops.show(t); }\n"
    unit = unit ++ "struct CastOps { void (*show)(Thing *); };\nstatic struct CastOps cast_ops = { show_a };\nstatic char *cast_bytes;\n"
    unit = unit ++ "void cast_show(Thing *t) { cast_bytes = (char *)&cast_ops; cast_ops.show(t); }\n"
    unit = unit ++ "void user_show(struct UserOps *ops, Thing *t) { ops->show(t); }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    let wanted = [
        "  one_show: lend",
        "  two_show: raw: retains param 0 (passed through the function pointer field show, which no unit decides: it is written in 2 places (show_a, show_b))",
        "  zeroed_show: raw: retains param 0 (passed through the function pointer field show, which no unit decides: a pointer to the record is passed to memset, which the proofs cannot read",
        "  cast_show: raw: retains param 0 (passed through the function pointer field show, which no unit decides: a pointer to the record is converted to another pointer type",
        "  user_show: raw: retains param 1 (passed through the function pointer field show, which no unit decides: the package never writes it (its value is the caller's))",
    ]
    var missing = 0
    for want in wanted:
        var found = false
        for line in report.split("\n"):
            if line.starts_with(want): found = true
        if not found:
            missing = missing + 1
            print("missing: " ++ want)
    if missing > 0: print(report)
    assert(missing == 0)
    print("ok")
