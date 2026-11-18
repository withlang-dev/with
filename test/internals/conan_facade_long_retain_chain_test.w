//! expect-stdout: ok
// #3174 (§16.2b.15): a retained parameter that travels through more than six
// calls is followed to the store that ends the chain. The report said "a
// chain of calls too deep to follow" and named nothing.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_long_retain_chain_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct node node;\nvoid keep(node *n);\n"
    assert(write_file(dep ++ "/include/chain.h", header) == 0)
    assert(write_file(src ++ "/chain.h", header) == 0)
    var unit = "#include \"chain.h\"\nstatic node *kept;\nstatic void k9(node *n) { kept = n; }\n"
    for i in 0..8:
        let at = 8 - i
        unit = unit ++ f"static void k{at}(node *n) \{ k{at + 1}(n); }\n"
    unit = unit ++ "void keep(node *n) { k1(n); }\n"
    assert(write_file(src ++ "/chain.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c chain.c\",\n  \"file\": \"chain.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"chain\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("chain", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    var keep_line = ""
    for line in report.split("\n"):
        if line.starts_with("  keep:"): keep_line = line.to_owned()
    let ok = keep_line.contains("retains param 0") and keep_line.contains("and on through further calls: stored in a global") and not keep_line.contains("too deep")
    if not ok: print(report)
    assert(ok)
    print("ok")
