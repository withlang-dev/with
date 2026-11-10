//! expect-stdout: ok
// D198: a header that does not compile on its own is still imported
// through the header that includes it. liblzma's `lzma/base.h` refuses a
// direct include ("Never include this file directly") and is reached
// through `lzma.h`; curl's `curl/easy.h` through `curl/curl.h`. The draft
// dropped every function such a header declares (xz_utils went from 132
// functions to none). The function is presented, imported by the umbrella;
// a header nothing includes (raylib's rcamera.h) still presents nothing.
// The header the facade imports must itself declare the function: an
// internal header that shares its file name with an installed one
// (liblzma's check/check.h beside lzma/check.h) was taken for it, and the
// facade named functions its import does not declare.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_umbrella_header_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include/tiny") == 0)
    assert(mkdir_p(src ++ "/tiny") == 0)
    assert(mkdir_p(build) == 0)
    let umbrella = "#define TINY_H_INTERNAL 1\ntypedef struct tiny_box tiny_box;\n#include \"tiny/part.h\"\n#undef TINY_H_INTERNAL\n"
    let part = "#ifndef TINY_H_INTERNAL\n#error Never include this file directly. Use <tiny.h> instead.\n#endif\ntiny_box *tiny_new(void);\nvoid tiny_free(tiny_box *b);\n"
    let orphan = "tiny_box *tiny_other(void);\n"
    assert(write_file(dep ++ "/include/tiny.h", umbrella) == 0)
    assert(write_file(dep ++ "/include/tiny/part.h", part) == 0)
    assert(write_file(dep ++ "/include/orphan.h", orphan) == 0)
    assert(write_file(src ++ "/tiny.h", umbrella) == 0)
    assert(write_file(src ++ "/tiny/part.h", part) == 0)
    assert(write_file(src ++ "/orphan.h", orphan) == 0)
    assert(mkdir_p(src ++ "/internal") == 0)
    assert(write_file(src ++ "/internal/part.h", "int tiny_hidden(tiny_box *b);\n") == 0)
    assert(write_file(src ++ "/tiny.c", "#include <stdlib.h>\n#include \"tiny.h\"\n#include \"orphan.h\"\n#include \"internal/part.h\"\nint tiny_hidden(tiny_box *b) { return b != 0; }\nstruct tiny_box { int n; };\ntiny_box *tiny_new(void) { tiny_box *b = malloc(sizeof(tiny_box)); b->n = 1; return b; }\nvoid tiny_free(tiny_box *b) { free(b); }\ntiny_box *tiny_other(void) { return tiny_new(); }\n") == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c tiny.c\",\n  \"file\": \"tiny.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"tiny\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("tiny", "1.0", dep, src, build)
    let facade = read_file(dep ++ "/facade.w") ?? ""
    let report = read_file(dep ++ "/facade-report.txt") ?? ""
    let ok = facade.contains("use c_import(\"tiny.h\"") and not facade.contains("tiny/part.h") and not facade.contains("orphan.h") and facade.contains("from tiny_new") and facade.contains("drop tiny_free") and not facade.contains("tiny_other") and not facade.contains("tiny_hidden") and report.contains("orphan.h")
    if not ok:
        print(facade)
        print(report)
    assert(ok)
    print("ok")
