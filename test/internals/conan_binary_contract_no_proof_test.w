//! expect-stdout: ok
// §31.6.3: a proof about compiled foreign code holds only for the build it
// analyzed. For a package linked as a prebuilt binary the units `with get`
// reads are not the build linked, so what they show is evidence: it is kept
// in `facade-evidence.txt` with what was analyzed, and grants nothing. The
// contract is drawn from the headers and the registry: a registry line
// stands, and a function only the source spoke for is no item of it. Every
// such result was written into the contract as a clause, and accepted.
use compiler.ConanClient
use std.fs
use std.os
use std.process

fn main:
    let root = "out/tmp/conan_binary_contract_no_proof_test"
    let dep = root ++ "/dep"
    let src = root ++ "/src"
    let build = root ++ "/build"
    let registry = root ++ "/registry-tree"
    assert(mkdir_p(dep ++ "/include") == 0)
    assert(mkdir_p(src) == 0)
    assert(mkdir_p(build) == 0)
    assert(mkdir_p(registry ++ "/registry/c/errs") == 0)
    let header = "const char *err_text(int code);\nconst char *err_name(int code);\nint errs_count(const char *name);\nint errs_len(const char *text);\n"
    assert(write_file(dep ++ "/include/errs.h", header) == 0)
    assert(write_file(src ++ "/errs.h", header) == 0)
    var unit = "#include \"errs.h\"\n"
    unit = unit ++ "const char *err_text(int code) { switch (code) { case 0: return \"no error\"; default: return \"unknown\"; } }\n"
    unit = unit ++ "const char *err_name(int code) { if (code == 7) return \"seven\"; return \"other\"; }\nint errs_count(const char *name) { int n = 0; while (name[n]) n++; return n; }\nint errs_len(const char *text) { int n = 0; while (text[n]) n++; return n; }\n"
    assert(write_file(src ++ "/errs.c", unit) == 0)
    let commands = "[\n{\n  \"directory\": \"" ++ src ++ "\",\n  \"command\": \"cc -I " ++ src ++ " -c errs.c\",\n  \"file\": \"errs.c\"\n}\n]\n"
    assert(write_file(build ++ "/compile_commands.json", commands) == 0)
    assert(write_file(dep ++ "/metadata.json", "{\"include_paths\": [\"include\"], \"libs\": [\"errs\"], \"package_id\": \"abc123\", \"package_revision\": \"def456\"}\n") == 0)
    // The registry speaks for errs_count; only the source speaks for errs_len.
    assert(write_file(registry ++ "/registry/c/errs/facts.w", "c facade errs:\n    fn errs_count\n        text param 0    // errs.h 3: the name is read to its NUL\n        lend    // errs.h 3: the name is not kept\n    fn err_name\n        nullable param 0    // errs.h 2: nothing presents err_name, so this line is not applied and the report says so\n") == 0)
    assert(set_env("WITH_REGISTRY", "file://" ++ current_dir() ++ "/" ++ registry) == 0)
    conan_write_binary_contract("errs", "1.0", dep, src, build)
    let evidence = read_file(dep ++ "/facade-evidence.txt") ?? ""
    let facade = read_file(dep ++ "/facade.w") ?? ""
    let ok = evidence.starts_with("evidence, not proof:") and evidence.contains("analyzed: the source of errs/1.0") and evidence.contains("package abc123") and
        evidence.contains("errs_len: lend (evidence: ") and not evidence.contains("(proof: ") and
        facade.contains("fn errs_count") and facade.contains("// registry: errs.h 3") and
        (read_file(dep ++ "/facade-report.txt") ?? "").contains("err_name: the registry's presentation lines are not applied") and
        not facade.contains("fn errs_len") and not facade.contains("proof") and not facade.contains("evidence: ")
    if not ok:
        print("--- evidence\n" ++ evidence)
        print("--- contract\n" ++ facade)
    assert(ok)
    print("ok")
