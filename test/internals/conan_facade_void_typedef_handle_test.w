//! expect-stdout: ok
// #3123 (§16.2b.15, D121): a handle behind `typedef void H;` (libcurl's
// CURL, CURLM, CURLSH) translates to `*mut c_void`, and the drafter read
// its producer as "returns *mut c_void, a pointer to no record". The
// typedef's name is the identity the header gives: a name a producer
// returns and a destroyer frees is a resource, and an operation on it says
// `of` that resource, since every void typedef is one representation to the
// checker. A typedef that is only a synonym for `void` (`GLvoid`) gains no
// producer and stays raw.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_facade_void_typedef_handle_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef void H;\ntypedef void GLvoid;\nH *h_new(void);\nvoid h_free(H *h);\nint h_size(const H *h);\nvoid upload(const GLvoid *data, int n);\n"
    assert(write_file(dep ++ "/include/vt.h", header) == 0)
    assert(write_file(src ++ "/vt.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include \"vt.h\"\nstruct impl { int n; };\n"
    unit = unit ++ "H *h_new(void) { struct impl *p = calloc(1, sizeof *p); return p; }\n"
    unit = unit ++ "void h_free(H *h) { free(h); }\n"
    unit = unit ++ "int h_size(const H *h) { return ((const struct impl *)h)->n; }\n"
    unit = unit ++ "void upload(const GLvoid *data, int n) { (void)data; (void)n; }\n"
    assert(write_file(src ++ "/vt.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c vt.c\",\n  \"file\": \"vt.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"vt\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("vt", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    let facade = read_file(dep ++ "/contract.w") ?? ""
    let resource = facade.contains("resource HHandle wraps *mut H\n        from h_new") and facade.contains("        drop h_free")
    let operation = facade.contains("    fn h_size\n        of HHandle")
    let synonym = report.contains("  upload: raw:") and not facade.contains("GLvoid")
    let ok = resource and operation and synonym and report.contains("3 presented safely, 1 raw")
    if not ok:
        print(report)
        print(facade)
    assert(ok)
    print("ok")
