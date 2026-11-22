//! expect-stdout: ok
// §31.7: `with get` records, beside the contract it draws, what the
// package's source proves against a grant a person might state
// (contract-proofs.txt): one fact a line, `<fn>\t<fact>\t<param>\t<proof>`.
//   keep         stores its parameter in a global      -> stores 0
//   node_free    frees its parameter                    -> frees 0
//   first_child  returns a field of its parameter       -> returns-part 0
//   forward      hands it to a function no unit defines -> nothing: the
//                proof stopped, which is weaker than a grant
//   node_new     a fresh allocation                     -> nothing
//   node_size    only reads                             -> nothing
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_contract_proofs_file_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Node { struct Node *child; int n; } Node;\nNode *node_new(void);\nvoid node_free(Node *n);\nvoid keep(Node *n);\nNode *first_child(Node *n);\nvoid forward(Node *n);\nint node_size(Node *n);\n"
    assert(write_file(dep ++ "/include/nodes.h", header) == 0)
    assert(write_file(src ++ "/nodes.h", header) == 0)
    var unit = "#include <stdlib.h>\n#include \"nodes.h\"\nvoid ext_take(Node *n);\nstatic Node *kept;\n"
    unit = unit ++ "Node *node_new(void) { return calloc(1, sizeof(Node)); }\n"
    unit = unit ++ "void node_free(Node *n) { free(n); }\n"
    unit = unit ++ "void keep(Node *n) { kept = n; }\n"
    unit = unit ++ "Node *first_child(Node *n) { return n->child; }\n"
    unit = unit ++ "void forward(Node *n) { ext_take(n); }\n"
    unit = unit ++ "int node_size(Node *n) { return n->n; }\n"
    assert(write_file(src ++ "/nodes.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c nodes.c\",\n  \"file\": \"nodes.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"nodes\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("nodes", "1.0", dep, src, build)
    let proofs = read_file(dep ++ "/contract-proofs.txt") ?? "<no contract-proofs.txt>"
    let ok = proofs.contains("keep\tstores\t0\tstored in a global\n") and proofs.contains("node_free\tfrees\t0\tfrees ") and proofs.contains("first_child\treturns-part\t0\t") and not proofs.contains("forward\t") and not proofs.contains("node_new\t") and not proofs.contains("node_size\t")
    if not ok:
        print(proofs)
        print(read_file(dep ++ "/contract-report.txt") ?? "")
    assert(ok)
    print("ok")
