//! expect-stdout: ok
// #3175: `str = buf` inside a body (zlib's gzgets) assigned a parameter to a
// local, and the evidence walker, which knew the parameters but not the
// locals, recorded a store into a global: 'retains param 1 (stored in a
// global)', 187 functions in 14 libraries of the #3116 survey. A local is an
// alias; only a name that is neither a parameter nor a local is a global.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_local_alias_not_global_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "int thing_fill(char *buf, int len);\nvoid thing_keep(char *buf);\n"
    assert(write_file(dep ++ "/include/thing.h", header) == 0)
    assert(write_file(src ++ "/thing.h", header) == 0)
    var unit = "#include \"thing.h\"\nstatic char *kept;\n"
    // The parameter rebound from its alias at the end (zlib's crc32_z:
    // `buf = (const unsigned char *)words`) is a write into the callee's own
    // frame, not a store of the local anywhere.
    unit = unit ++ "int thing_fill(char *buf, int len) { char *str = buf; int n = len; while (n-- > 0) *str++ = 'x'; buf = str; return (int)(buf - str) + len; }\n"
    unit = unit ++ "void thing_keep(char *buf) { kept = buf; }\n"
    assert(write_file(src ++ "/thing.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c thing.c\",\n  \"file\": \"thing.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"thing\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("thing", "1.0", dep, src, build)
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    var fill_line = ""
    var keep_line = ""
    for line in report.split("\n"):
        if line.starts_with("  thing_fill:"): fill_line = line.to_owned()
        if line.starts_with("  thing_keep:"): keep_line = line.to_owned()
    let ok = not fill_line.contains("stored in a global") and keep_line.contains("stored in a global")
    if not ok: print(report)
    assert(not fill_line.contains("stored in a global"), fill_line)
    assert(keep_line.contains("stored in a global"), keep_line)
    print("ok")
