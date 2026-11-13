//! expect-stdout: ok
// §31.9 rule 5, §31.7: a registry line a proof contradicts is an error
// naming both; a facts file may not override. The registry says
// `first_child` produces a node the caller owns; the source shows every
// return is a field of its parameter. The draft kept the proof and noted
// `DISAGREES` in the report, and `with get` added the package all the same.
use compiler.ConanClient
use std.fs
use std.process
use std.os.current_dir

fn main:
    let root = "out/tmp/conan_registry_line_contradicts_proof_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    let registry = root ++ "/registry"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    assert(mkdir_p(registry ++ "/registry/c/nodes") == 0)
    let header = "typedef struct Node { struct Node *child; int n; } Node;\nNode *node_new(void);\nvoid node_free(Node *n);\nNode *first_child(Node *n);\n"
    assert(write_file(dep ++ "/include/nodes.h", header) == 0)
    assert(write_file(src ++ "/nodes.h", header) == 0)
    let unit = "#include <stdlib.h>\n#include \"nodes.h\"\nNode *node_new(void) { return calloc(1, sizeof(Node)); }\nvoid node_free(Node *n) { free(n); }\nNode *first_child(Node *n) { return n->child; }\n"
    assert(write_file(src ++ "/nodes.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c nodes.c\",\n  \"file\": \"nodes.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"nodes\"]}\n") == 0)
    assert(write_file(registry ++ "/registry/c/nodes/facts.w", "c facts nodes:\n    resource Tree wraps *mut Node\n        from first_child    // nodes.h 4: \"returns a new node the caller frees\"\n        drop node_free    // nodes.h 3: \"frees the node\"\n") == 0)
    assert(set_env("WITH_REGISTRY", "file://" ++ current_dir() ++ "/" ++ registry) == 0)
    conan_write_facade("nodes", "1.0", dep, src, build)
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    conan_refuse_contradicted_registry("nodes", dep)
    let said = conan_facts_contradicted()
    let ok = said.contains("nodes:") and said.contains("first_child") and said.contains("nodes.h 4") and said.contains("DISAGREES: the proof returns a borrow") and not file_exists(dep ++ "/contract.w") and not file_exists(dep ++ "/contract-proofs.txt")
    if not ok:
        print(said)
        print(report)
    assert(ok)
    print("ok")
