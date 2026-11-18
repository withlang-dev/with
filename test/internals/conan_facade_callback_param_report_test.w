//! expect-stdout: ok
// #3178 (§16.2b.9, §16.2b.15): a function kept raw by a callback parameter
// is reported with the parameter's position and the clause that would
// describe it: the userdata pairing when a `void *` carries the userdata,
// and the bare 'callback param N' when none does.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_callback_param_report_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "void each(void (*cb)(int, void *), void *ud);\nvoid each_bare(int n, void (*cb)(int));\n"
    assert(write_file(dep ++ "/include/cbs.h", header) == 0)
    assert(write_file(src ++ "/cbs.h", header) == 0)
    var unit = "#include \"cbs.h\"\n"
    unit = unit ++ "void each(void (*cb)(int, void *), void *ud) { (void)cb; (void)ud; }\n"
    unit = unit ++ "void each_bare(int n, void (*cb)(int)) { for (int i = 0; i < n; i++) cb(i); }\n"
    assert(write_file(src ++ "/cbs.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c cbs.c\",\n  \"file\": \"cbs.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"cbs\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("cbs", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    var each_line = ""
    var bare_line = ""
    for line in report.split("\n"):
        if line.starts_with("  each:"): each_line = line.to_owned()
        if line.starts_with("  each_bare:"): bare_line = line.to_owned()
    let ok = each_line.contains("parameter of a callback or array type the facade does not describe") and each_line.contains("(param 0)") and each_line.contains("'callback param 0 userdata param 1'") and bare_line.contains("(param 1)") and bare_line.contains("no `void *` userdata parameter") and bare_line.contains("'callback param 1', which takes a function or a closure that captures nothing")
    if not ok: print(report)
    assert(ok)
    print("ok")
