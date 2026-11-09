//! expect-stdout: ok
// #3167: the install relocates the header (cjson's source `cJSON.h` installs
// as `include/cjson/cJSON.h`). No suffix of the source path exists under the
// include dir, and every function the header declares was dropped as
// "declared only by headers the package does not install" (cjson presented
// 1 of 79). The installed file with the source header's bytes is the import
// spelling; the facade imports it and presents the function.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_relocated_header_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include/tiny") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "int tiny_twice(int x);\n"
    assert(write_file(dep ++ "/include/tiny/tiny.h", header) == 0)
    assert(write_file(src ++ "/tiny.h", header) == 0)
    assert(write_file(src ++ "/tiny.c", "#include \"tiny.h\"\nint tiny_twice(int x) { return x * 2; }\n") == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c tiny.c\",\n  \"file\": \"tiny.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"tiny\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("tiny", "1.0", dep, src, build)
    // A value-only function imports nothing (the facade's `use c_import`
    // lines serve the resources it presents); the report is the evidence.
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    let first = report.split("\n")[0]
    if not first.starts_with("facade tiny: 1 functions") or not report.contains("  tiny_twice: "):
        print(report)
    assert(first.starts_with("facade tiny: 1 functions"))
    assert(report.contains("  tiny_twice: "))
    print("ok")
