//! expect-stdout: ok
// #3374 (§31.7): a store into a field of a record that lives in the
// function's own frame is no proof that the function keeps the parameter
// past the call. sqlite3Prepare has `Parse sParse; … sParse.db = db;`, and
// the proof read it as a store, so a stated `lend` on sqlite3_prepare_v2
// and sqlite3_exec was refused wherever sqlite3 is built from source.
//   scratch      stores it in a field of a local record        -> nothing
//   by_value     stores it in a field of a by-value parameter  -> nothing
//   through      calls scratch                                 -> nothing
//   keep_static  the record is a static local                  -> stores 0
//   keep_in      stores it through a pointer to a record       -> stores 0
//   keep_deep    the local is a pointer: `p->child = n`        -> stores 0
//   copy_out     the local record is copied through a pointer   -> stores 1
//   give         the local record is returned by value         -> stores 0
//   by_address   the record's address goes to a reader          -> nothing
// A drawn contract still keeps `scratch`'s parameter raw: the record may be
// copied out or read by a callee, which the proof does not follow.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let root = "out/tmp/conan_contract_proofs_frame_record_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    let header = "typedef struct Node { struct Node *child; int n; } Node;\ntypedef struct Pair { Node *a; Node *b; } Pair;\nint scratch(Node *n);\nint by_value(Pair p, Node *n);\nint through(Node *n);\nvoid keep_static(Node *n);\nvoid keep_in(Node *holder, Node *n);\nvoid keep_deep(Node *holder, Node *n);\nvoid copy_out(Pair *out, Node *n);\nPair give(Node *n);\nint by_address(Node *n);\n"
    assert(write_file(dep ++ "/include/nodes.h", header) == 0)
    assert(write_file(src ++ "/nodes.h", header) == 0)
    var unit = "#include \"nodes.h\"\n"
    unit = unit ++ "int scratch(Node *n) { Pair work; work.a = n; work.b = 0; return work.a->n; }\n"
    unit = unit ++ "int by_value(Pair p, Node *n) { p.a = n; return p.a->n; }\n"
    unit = unit ++ "int through(Node *n) { return scratch(n); }\n"
    unit = unit ++ "void keep_static(Node *n) { static Pair held; held.a = n; }\n"
    unit = unit ++ "void keep_in(Node *holder, Node *n) { holder->child = n; }\n"
    unit = unit ++ "void keep_deep(Node *holder, Node *n) { Node *p = holder; p->child = n; }\n"
    unit = unit ++ "void copy_out(Pair *out, Node *n) { Pair work; work.a = n; work.b = 0; *out = work; }\n"
    unit = unit ++ "Pair give(Node *n) { Pair work; work.a = n; work.b = 0; return work; }\n"
    unit = unit ++ "static int peek(const Pair *p) { return p->a->n; }\n"
    unit = unit ++ "int by_address(Node *n) { Pair work; work.a = n; work.b = 0; return peek(&work); }\n"
    assert(write_file(src ++ "/nodes.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c nodes.c\",\n  \"file\": \"nodes.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"nodes\"]}\n") == 0)
    assert(set_env("WITH_REGISTRY", "file:///nonexistent-registry") == 0)
    conan_write_facade("nodes", "1.0", dep, src, build)
    let proofs = read_file(dep ++ "/contract-proofs.txt") ?? "<no contract-proofs.txt>"
    let report = read_file(dep ++ "/contract-report.txt") ?? ""
    let ok = not proofs.contains("scratch\t") and not proofs.contains("by_value\t") and not proofs.contains("through\t") and proofs.contains("keep_static\tstores\t0\tstored in a field\n") and proofs.contains("keep_in\tstores\t1\tstored in a field\n") and proofs.contains("keep_deep\tstores\t1\tstored in a field\n") and proofs.contains("copy_out\tstores\t1\tstored in a field\n") and proofs.contains("give\tstores\t0\tstored in a field\n") and not proofs.contains("by_address\t") and report.contains("held in a record of the function's own frame")
    if not ok:
        print(proofs)
        print(report)
    assert(ok)
    print("ok")
