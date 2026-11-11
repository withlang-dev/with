//! expect-stdout: ok
// #3176: a record with a proven producer and a proven destroyer that is
// still no resource (its producer takes a pointer the facade does not
// describe: curl_mime_init's `CURL *`) was reported as 'the package has no
// single destroyer of it: a registry fact names one', and its record line
// said the same. Both now name the parameter.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_undescribed_producer_param_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Opaque Opaque;\ntypedef struct Thing Thing;\nThing *thing_make(Opaque *owner);\nvoid thing_free(Thing *t);\n"
    assert(write_file(dep ++ "/include/thing.h", header) == 0)
    assert(write_file(src ++ "/thing.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include \"thing.h\"\nstruct Thing { int n; };\n"
    unit = unit ++ "Thing *thing_make(Opaque *owner) { (void)owner; return (Thing *)malloc(sizeof(Thing)); }\n"
    unit = unit ++ "void thing_free(Thing *t) { free(t); }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    var make_line = ""
    var record_line = ""
    for line in report.split("\n"):
        if line.starts_with("  thing_make:"): make_line = line.to_owned()
        if line.starts_with("  Thing:"): record_line = line.to_owned()
    let ok = make_line.contains("dropped by thing_free, but param 0 is *mut Opaque, which the facade does not describe") and record_line.contains("but no resource: param 0 of thing_make is *mut Opaque") and not report.contains("no single destroyer")
    if not ok: print(report)
    assert(make_line.contains("dropped by thing_free, but param 0 is *mut Opaque, which the facade does not describe"), make_line)
    assert(record_line.contains("but no resource: param 0 of thing_make is *mut Opaque"), record_line)
    print("ok")
