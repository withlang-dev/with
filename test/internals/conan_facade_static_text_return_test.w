//! expect-stdout: ok
// #3127 (§16.2b.8): a function whose every return is a string literal, or a
// call of a package function that returns static text, presents as
// `returns static CStr` from the proof (curl_easy_strerror, sqlite3_errstr,
// zError). It read "raw: returns *const c_char, a pointer to no record".
// A static buffer the function writes, and a parameter handed back, stay
// raw: neither is immutable static text.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_static_text_return_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "const char *err_text(int code);\nconst char *err_name(int code);\nconst char *lib_version(void);\nconst char *pick(const char *a);\n"
    assert(write_file(dep ++ "/include/errs.h", header) == 0)
    assert(write_file(src ++ "/errs.h", header) == 0)
    var unit = "#include <stdio.h>\n#include \"errs.h\"\n"
    unit = unit ++ "const char *err_text(int code) { switch (code) { case 0: return \"no error\"; case 1: return \"out of memory\"; default: return code < 0 ? \"negative\" : \"unknown\"; } }\n"
    unit = unit ++ "const char *err_name(int code) { if (code == 7) return \"seven\"; return err_text(code); }\n"
    unit = unit ++ "const char *lib_version(void) { static char buf[32]; snprintf(buf, sizeof buf, \"errs %d\", 1); return buf; }\n"
    unit = unit ++ "const char *pick(const char *a) { return a; }\n"
    assert(write_file(src ++ "/errs.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c errs.c\",\n  \"file\": \"errs.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"errs\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("errs", "1.0", dep, src, build)
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    let facade = read_file(dep ++ "/facade.w") ?? ""
    var text_line = ""
    var name_line = ""
    var version_line = ""
    var pick_line = ""
    for line in report.split("\n"):
        if line.starts_with("  err_text:"): text_line = line.to_owned()
        if line.starts_with("  err_name:"): name_line = line.to_owned()
        if line.starts_with("  lib_version:"): version_line = line.to_owned()
        if line.starts_with("  pick:"): pick_line = line.to_owned()
    let ok = not text_line.contains("raw") and not name_line.contains("raw") and version_line.contains("raw") and pick_line.contains("raw") and facade.contains("fn err_text\n        returns static CStr") and facade.contains("fn err_name\n        returns static CStr") and not facade.contains("fn lib_version") and not facade.contains("fn pick")
    if not ok:
        print(report)
        print(facade)
    assert(ok)
    print("ok")
