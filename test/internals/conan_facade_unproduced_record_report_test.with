//! expect-stdout: ok
// #3176 (§16.2b.15): a record the package destroys and never produces is
// no resource, and its line says what the proofs do know (the destroyer)
// and the two contracts a person could state: a producer named with
// 'from', or a caller-allocated record filled in place with 'init'.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_unproduced_record_report_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Slot Slot;\nvoid slot_end(Slot *s);\n"
    assert(write_file(dep ++ "/include/slot.h", header) == 0)
    assert(write_file(src ++ "/slot.h", header) == 0)
    let unit = "#include <stdlib.h>\n#include \"slot.h\"\nstruct Slot { int n; };\nvoid slot_end(Slot *s) { free(s); }\n"
    assert(write_file(src ++ "/slot.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c slot.c\",\n  \"file\": \"slot.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"slot\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("slot", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    let ok = report.contains("  Slot: destroyed but never produced here; no resource (destroyed by slot_end; a contract states 'resource <Name> wraps *mut Slot' with 'from <fn>' naming what produces it, or, where the caller allocates the record and a function fills it, 'resource <Name> wraps Slot' with 'init <fn>(self)' (§16.2b.3))")
    if not ok: print(report)
    assert(ok)
    print("ok")
