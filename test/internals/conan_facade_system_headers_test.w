//! expect-stdout: ok
// #2635: `with get` derives a package's facade by parsing its units the way
// c_import does. On Windows that means the windows-gnu target against the
// SDK's libc; without it no system header was found, every unit failed to
// parse, and the facade came out with 0 functions. A unit and a header that
// include <stdio.h> must yield the declared function on every host.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_system_headers_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "#include <stdio.h>\nint tiny_twice(int x);\n"
    assert(write_file(dep ++ "/include/tiny.h", header) == 0)
    assert(write_file(src ++ "/tiny.h", header) == 0)
    assert(write_file(src ++ "/tiny.c", "#include <stdio.h>\n#include \"tiny.h\"\nint tiny_twice(int x) { return x * 2; }\n") == 0)
    let abs_src = src
    let commands = "[\n{\n  \"directory\": \"" ++ abs_src ++ "\",\n  \"command\": \"cc -I " ++ abs_src ++ " -c tiny.c\",\n  \"file\": \"tiny.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"tiny\"]}\n") == 0)
    // No registry: the facade comes from the package's own evidence.
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("tiny", "1.0", dep, src, build)
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    let lines = report.split("\n")
    let first = lines[0]
    if not first.starts_with("facade tiny: 1 functions"):
        print(report)
    assert(first.starts_with("facade tiny: 1 functions"))
    print("ok")
