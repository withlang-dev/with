//! expect-stdout: ok
// #3175 (§16.2b.15): a parameter the proof sees stored is reported with the
// place it was stored in, as the source spells it. "stored" alone did not
// let a reader tell a registration from a scratch slot the function sets
// for its own call and restores (zlib's deflateSetDictionary swaps
// `strm->next_in`).
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_store_place_report_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct stream { const unsigned char *next_in; unsigned avail_in; } stream;\nint set_dictionary(stream *strm, const unsigned char *dictionary, unsigned n);\n"
    assert(write_file(dep ++ "/include/st.h", header) == 0)
    assert(write_file(src ++ "/st.h", header) == 0)
    let unit = "#include \"st.h\"\nint set_dictionary(stream *strm, const unsigned char *dictionary, unsigned n) { const unsigned char *next = strm->next_in; strm->next_in = dictionary; strm->avail_in = n; strm->next_in = next; return 0; }\n"
    assert(write_file(src ++ "/st.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c st.c\",\n  \"file\": \"st.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"st\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("st", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    var line = ""
    for row in report.split("\n"):
        if row.starts_with("  set_dictionary:"): line = row.to_owned()
    let ok = line.contains("retains param 1 (stored in a field, `strm->next_in`)")
    if not ok: print(report)
    assert(ok)
    print("ok")
