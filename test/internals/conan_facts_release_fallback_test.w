//! expect-stdout: ok
// The registry's main may state a fact in words a released compiler does
// not read yet (`runs threads` reached main after v0.15.1 shipped). `with
// get` then failed for that package on every released compiler. The facts
// its own release published are the newest it provably reads: it uses
// those, says so, and the facade is written.
use compiler.ConanClient
use std.fs
use std.os
use std.process

fn main:
    let root = "out/tmp/conan_facts_release_fallback_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    let newer = root ++ "/main"
    let release = root ++ "/release"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    assert(mkdir_p(newer ++ "/registry/c/tiny") == 0)
    assert(mkdir_p(release ++ "/registry/c/tiny") == 0)
    let header = "int tiny_twice(int x);\n"
    assert(write_file(dep ++ "/include/tiny.h", header) == 0)
    assert(write_file(src ++ "/tiny.h", header) == 0)
    assert(write_file(src ++ "/tiny.c", "#include \"tiny.h\"\nint tiny_twice(int x) { return x * 2; }\n") == 0)
    assert(write_file(build ++ "/compile_commands.json", "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c tiny.c\",\n  \"file\": \"tiny.c\"\n}\n]\n") == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"tiny\"]}\n") == 0)
    // Main's file: a statement from the future.
    assert(write_file(newer ++ "/registry/c/tiny/facts.w", "c facts tiny:\n    hovers gently    // tiny.h, a word no compiler reads yet\n") == 0)
    // The release's file: words this compiler reads.
    let published = "c facts tiny:\n    runs threads    // tiny.h, the release's own fact\n"
    assert(write_file(release ++ "/registry/c/tiny/facts.w", published) == 0)
    assert(set_env("WITH_REGISTRY", "file://" ++ current_dir() ++ "/" ++ newer) == 0)
    assert(set_env("WITH_REGISTRY_RELEASE", "file://" ++ current_dir() ++ "/" ++ release) == 0)
    conan_write_facade("tiny", "1.0", dep, src, build)
    let refused = conan_facts_refused()
    let ok = refused.len() == 0 and file_exists(dep ++ "/contract.w") and read_file(dep ++ "/facts.w").unwrap() == published and read_file(dep ++ "/contract.w").unwrap().contains("runs threads")
    if not ok: print("refused: " ++ refused)
    assert(ok)
    print("ok")
