//! expect-stdout: ok
// §16.2b.15: a facts file states the role of a function-pointer field, one
// per line with its citation. A library that allocates and releases through
// hooks the program supplies (pcre2's memctl) has no body behind the call
// for the proofs to read: its producer "returns what the function pointer
// field alloc, which no unit decides". With the roles stated, a call
// through the `allocator` field is a fresh allocation the caller owns and
// one through the `deallocator` field destroys its argument, so the pair is
// a resource. A role is never drawn from the field's name.
use compiler.ConanClient
use std.fs
use std.os
use std.process

fn draft(root: &str, with_facts: bool) -> str:
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    let registry = root ++ "/registry"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    assert(mkdir_p(registry ++ "/registry/c/hooked") == 0)
    let header = "typedef struct hooks { void *(*alloc)(unsigned long size, void *data); void (*release)(void *block, void *data); void *data; } hooks;\nextern hooks box_hooks;\ntypedef struct box box;\nbox *box_new(void);\nvoid box_free(box *b);\n"
    assert(write_file(dep ++ "/include/hooked.h", header) == 0)
    assert(write_file(src ++ "/hooked.h", header) == 0)
    assert(write_file(src ++ "/hooked.c", "#include \"hooked.h\"\nhooks box_hooks;\nstruct box { int n; };\nbox *box_new(void) { box *b = box_hooks.alloc(sizeof(box), box_hooks.data); if (!b) return 0; b->n = 1; return b; }\nvoid box_free(box *b) { box_hooks.release(b, box_hooks.data); }\n") == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c hooked.c\",\n  \"file\": \"hooked.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"hooked\"]}\n") == 0)
    assert(write_file(registry ++ "/registry/c/hooked/facts.w", "c contract hooked:\n    field alloc of hooks is allocator    // hooked.h: alloc returns a block the caller owns\n    field release of hooks is deallocator    // hooked.h: release frees the block\n    field data of hooks is context    // hooked.h: handed back to both hooks\n") == 0)
    assert(set_env("WITH_REGISTRY", if with_facts: "file://" ++ current_dir() ++ "/" ++ registry else: "file:///nonexistent-registry") == 0)
    conan_write_facade("hooked", "1.0", dep, src, build)
    (read_file(dep ++ "/contract.w") ?? "") ++ "\n====\n" ++ (read_file(dep ++ "/contract-report.txt") ?? "")

fn main:
    let bare = draft("out/tmp/conan_facade_field_roles_test/bare", false)
    let stated = draft("out/tmp/conan_facade_field_roles_test/stated", true)
    let ok = not bare.contains("from box_new") and bare.contains("the function pointer field alloc") and stated.contains("from box_new") and stated.contains("drop box_free") and stated.contains("//   field alloc of hooks is allocator    // registry: hooked.h: alloc returns a block the caller owns")
    if not ok:
        print(bare)
        print(stated)
    assert(ok)
    print("ok")
