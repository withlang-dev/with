//! expect-stdout: ok
// D198 (§16.2b.3, §16.2b.15): the registry states a by-value resource
// (`resource R wraps Record`), its producer, its drop and its operations,
// each with its citation; a pair is never drawn from the functions' names.
// The draft carries the stanza as written with `registry:` provenance. The
// reader refused anything but `wraps *mut record`, and the package then
// got no facade at all.
use compiler.ConanClient
use std.fs
use std.process
use std.os

fn main:
    let root = "out/tmp/conan_facade_by_value_resource_facts_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    let registry = root ++ "/registry"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    assert(mkdir_p(registry ++ "/registry/c/pix") == 0)
    let header = "typedef struct { int *data; int n; } Pix;\nPix pix_load(void);\nvoid pix_unload(Pix p);\nint pix_at(Pix p, int i);\n"
    assert(write_file(dep ++ "/include/pix.h", header) == 0)
    assert(write_file(src ++ "/pix.h", header) == 0)
    assert(write_file(src ++ "/pix.c", "#include <stdlib.h>\n#include \"pix.h\"\nPix pix_load(void) { Pix p; p.data = malloc(sizeof(int) * 4); p.n = 4; return p; }\nvoid pix_unload(Pix p) { free(p.data); }\nint pix_at(Pix p, int i) { return p.data[i]; }\n") == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c pix.c\",\n  \"file\": \"pix.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"pix\"]}\n") == 0)
    assert(write_file(registry ++ "/registry/c/pix/facts.w", "c facts pix:\n    resource Pixels wraps Pix\n        from pix_load    // pix.h: the caller owns the buffer\n        drop pix_unload    // pix.h: frees the buffer\n    fn pix_at\n        of Pixels    // pix.c: reads data[i], stores nothing\n") == 0)
    assert(set_env("WITH_REGISTRY", "file://" ++ current_dir() ++ "/" ++ registry) == 0)
    conan_write_facade("pix", "1.0", dep, src, build)
    let facade = read_file(dep ++ "/contract.w") ?? ""
    let ok = facade.contains("use c_import(\"pix.h\"") and facade.contains("    resource Pixels wraps Pix\n        from pix_load    // registry: pix.h: the caller owns the buffer\n        drop pix_unload    // registry: pix.h: frees the buffer\n    fn pix_at\n        of Pixels    // registry: pix.c: reads data[i], stores nothing\n")
    if not ok:
        print(facade)
        print(read_file(dep ++ "/contract-report.txt") ?? "")
    assert(ok)
    print("ok")
