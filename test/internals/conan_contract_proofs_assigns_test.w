//! expect-stdout: ok
// §31.8.6: `with get` records each function of the package's source that
// assigns a global, by the global's name (contract-proofs.txt,
// `<fn>\tassigns\t<global>\t<proof>`), for a destroyer clause that names
// the global to be held against.
//   set_release    assigns the global from its parameter -> assigns
//   reset_release  assigns it a function                 -> assigns
//   node_count     assigns a local                       -> nothing
//   node_free      calls through the global              -> nothing
//   node_configure calls set_release (#3338)             -> assigns, through it
//   node_shutdown  calls a static that assigns it        -> assigns, through it
//   node_touch     calls a function that assigns nothing -> nothing
//   set_release2   assigns a global of a typedef'd pointer   -> assigns
//   node_tally     assigns a global that holds no function -> nothing
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_contract_proofs_assigns_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Node { int n; } Node;\nNode *node_new(void);\nvoid node_free(Node *n);\nextern void (*node_release)(Node *n);\ntypedef void (*release_fn)(Node *n);\nextern release_fn node_release2;\nextern int node_total;\nvoid set_release2(release_fn f);\nvoid node_tally(void);\nvoid set_release(void (*f)(Node *n));\nvoid reset_release(void);\nint node_count(Node *n);\nvoid node_configure(void);\nvoid node_shutdown(void);\nvoid node_touch(Node *n);\n"
    assert(write_file(dep ++ "/include/nodes.h", header) == 0)
    assert(write_file(src ++ "/nodes.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include \"nodes.h\"\nstatic void plain_release(Node *n) { free(n); }\nvoid (*node_release)(Node *n) = plain_release;\n"
    unit = unit ++ "Node *node_new(void) { return calloc(1, sizeof(Node)); }\n"
    unit = unit ++ "void node_free(Node *n) { node_release(n); }\n"
    unit = unit ++ "void set_release(void (*f)(Node *n)) { node_release = f; }\n"
    unit = unit ++ "void reset_release(void) { node_release = plain_release; }\n"
    unit = unit ++ "int node_count(Node *n) { int c; c = n->n; return c; }\n"
    unit = unit ++ "release_fn node_release2 = plain_release;\nint node_total = 0;\n"
    unit = unit ++ "void set_release2(release_fn f) { node_release2 = f; }\n"
    unit = unit ++ "void node_tally(void) { node_total = node_total + 1; }\n"
    unit = unit ++ "static void quiet_reset(void) { node_release = plain_release; }\n"
    unit = unit ++ "void node_configure(void) { set_release(plain_release); }\n"
    unit = unit ++ "void node_shutdown(void) { quiet_reset(); }\n"
    unit = unit ++ "void node_touch(Node *n) { node_count(n); }\n"
    assert(write_file(src ++ "/nodes.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c nodes.c\",\n  \"file\": \"nodes.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"nodes\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("nodes", "1.0", dep, src, build)
    let proofs = read_file(dep ++ "/contract-proofs.txt") ?? "<no contract-proofs.txt>"
    let ok = proofs.contains("set_release\tassigns\tnode_release\tthe body of set_release assigns node_release\n") and proofs.contains("reset_release\tassigns\tnode_release\t") and not proofs.contains("node_count\tassigns") and not proofs.contains("node_free\tassigns") and proofs.contains("node_configure\tassigns\tnode_release\tnode_configure reaches set_release, whose body assigns node_release\n") and proofs.contains("node_shutdown\tassigns\tnode_release\tnode_shutdown reaches quiet_reset, whose body assigns node_release\n") and not proofs.contains("node_touch\tassigns") and proofs.contains("set_release2\tassigns\tnode_release2\t") and not proofs.contains("node_tally\tassigns")
    if not ok:
        print(proofs)
        print(read_file(dep ++ "/contract-report.txt") ?? "")
    assert(ok)
    print("ok")
