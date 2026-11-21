//! expect-stdout: ok
// #3173 (§16.2b.3, D198): a record the caller allocates and an init/end
// pair fill and release (`z_stream` between `deflateInit` and `deflateEnd`)
// is an in-place resource. The draft proposes `init` and `drop` only from a
// proof over the source: the init function stores a fresh allocation into a
// field of the record it is handed, and the end function frees that field.
// Never from the functions' names: `codec_reset`, which frees nothing, is
// no drop, and `other_start`, which allocates nothing, is no init.
use compiler.ConanClient
use std.fs
use std.os
use std.process

fn main:
    let root = "out/tmp/conan_facade_inplace_resource_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct codec { void *state; int total; } codec;\nint codec_open(codec *c, int level);\nint codec_step(codec *c, int flush);\nvoid codec_reset(codec *c);\nint codec_close(codec *c);\ntypedef struct other { void *state; int n; } other;\nvoid other_start(other *o);\nint other_get(const other *o);\n"
    assert(write_file(dep ++ "/include/codec.h", header) == 0)
    assert(write_file(src ++ "/codec.h", header) == 0)
    assert(write_file(src ++ "/codec.c", "#include <stdlib.h>\n#include \"codec.h\"\nstruct inner { int level; int count; };\nint codec_open(codec *c, int level) { struct inner *s = malloc(sizeof(struct inner)); if (!s) return -1; s->level = level; s->count = 0; c->state = s; c->total = 0; return 0; }\nint codec_step(codec *c, int flush) { struct inner *s = c->state; s->count = s->count + flush; c->total = c->total + 1; return s->count; }\nvoid codec_reset(codec *c) { struct inner *s = c->state; s->count = 0; c->total = 0; }\nint codec_close(codec *c) { free(c->state); c->state = 0; return 0; }\nvoid other_start(other *o) { o->state = 0; o->n = 1; }\nint other_get(const other *o) { return o->n; }\n") == 0)
    assert(write_file(build ++ "/compile_commands.json", "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c codec.c\",\n  \"file\": \"codec.c\"\n}\n]\n") == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"codec\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("codec", "1.0", dep, src, build)
    let contract = read_file(dep ++ "/contract.w") ?? ""
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    let ok = contract.contains("    resource Codec wraps codec\n") and contract.contains("        init codec_open(self)") and contract.contains("        drop codec_close") and contract.contains("    fn codec_step\n        lend") and contract.contains("    fn codec_reset\n        lend") and not contract.contains("resource Other")
    if not ok:
        print(contract)
        print(report)
    assert(ok)
    print("ok")
