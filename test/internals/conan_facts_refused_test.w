//! expect-stdout: ok
// #3241: the registry's facts file for a package could not be read, `with
// get` said so in passing, wrote no facade and exited 0: every program
// written against the facade then failed with raw-call errors that named no
// facts file. The refusal is recorded for the command, which fails.
use compiler.ConanClient
use std.fs
use std.os
use std.process

fn main:
    let root = "out/tmp/conan_facts_refused_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    let registry = root ++ "/registry"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    assert(mkdir_p(registry ++ "/registry/c/tiny") == 0)
    let header = "int tiny_twice(int x);\n"
    assert(write_file(dep ++ "/include/tiny.h", header) == 0)
    assert(write_file(src ++ "/tiny.h", header) == 0)
    assert(write_file(src ++ "/tiny.c", "#include \"tiny.h\"\nint tiny_twice(int x) { return x * 2; }\n") == 0)
    assert(write_file(build ++ "/compile_commands.json", "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c tiny.c\",\n  \"file\": \"tiny.c\"\n}\n]\n") == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"tiny\"]}\n") == 0)
    assert(write_file(registry ++ "/registry/c/tiny/facts.w", "c contract tiny:\n    fn tiny_twice\n        lend\n") == 0)
    assert(set_env("WITH_REGISTRY", "file://" ++ current_dir() ++ "/" ++ registry) == 0)
    assert(conan_facts_refused().len() == 0)
    conan_write_facade("tiny", "1.0", dep, src, build)
    let refused = conan_facts_refused()
    let ok = refused.starts_with("tiny: ") and refused.contains("facts.w:3: a fact needs its citation") and not file_exists(dep ++ "/contract.w")
    if not ok: print(refused)
    assert(ok)
    print("ok")
