//! expect-stdout: ok

use pre_d_build_runner

// #3117: a call of a function the fetched package's facade leaves raw
// quotes the report's reason and names the report `with get` wrote beside
// the facade.
fn main:
    let dir = p7_prepare_case("3117_facade_report", "facade_report")
    p7_write(dir, "with.toml", "[package]\nname = \"facade_report\"\nversion = \"0.1.0\"\n\n[deps]\nc.demo = \"1.0\"\n")
    p7_write(dir, ".with/deps/c/demo/1.0/metadata.json", "{\n  \"name\": \"demo\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": [],\n  \"defines\": [],\n  \"link_args\": [],\n  \"components\": []\n}\n")
    p7_write(dir, ".with/deps/c/demo/1.0/include/demo.h", "static inline int demo_len(const int *xs) { return xs[0]; }\nstatic inline int demo_add(int a, int b) { return a + b; }\n")
    p7_write(dir, ".with/deps/c/demo/1.0/contract.w", "use c_import(\"demo.h\")\n\nc contract demo:\n    fn demo_add\n")
    p7_write(dir, ".with/deps/c/demo/1.0/contract-report.txt", "facade demo: 2 functions, 1 presented safely, 1 raw\n  demo_add: value-only call\n  demo_len: raw: parameter of unmodeled pointer type *const i32\n")
    p7_write(dir, "src/main.w", "use c_import(\"demo.h\")\n\nfn main:\n    let xs: *const i32 = null\n    let v = demo_len(xs)\n    print(f\"{demo_add(1, 2)}\")\n")
    p7_assert_failure_contains(p7_run(dir, "raw", "check\0src/main.w\0"), "the facade of demo leaves `demo_len` raw: parameter of unmodeled pointer type *const i32 (", "a raw call names its report line")

    p7_assert_failure_contains(p7_run(dir, "raw-command", "check\0src/main.w\0"), "(`with contract report c.demo demo_len`)", "the note names the command that prints the line")

    // `with contract report c.<package> [function]`: what is presented is the
    // contract `with analyze <contract> contract` prints, line for line; what
    // is raw is the report's reason.
    let one = p7_run(dir, "one", "contract\0report\0c.demo\0demo_len\0")
    p7_assert_success(one, "the report of one raw function")
    assert(one.stdout.trim() == "demo_len: raw: parameter of unmodeled pointer type *const i32")
    let whole = p7_run(dir, "whole", "contract\0report\0c.demo\0")
    p7_assert_success(whole, "the whole report")
    let view = p7_run(dir, "view", "analyze\0.with/deps/c/demo/1.0/contract.w\0contract\0")
    p7_assert_success(view, "the contract view of the drawn contract")
    let add_line = "fn demo_add; contract:demo@"
    assert(view.stdout.contains(add_line) and whole.stdout.contains(add_line))
    assert(whole.stdout.contains("contract-audit: violations=0 ok") and whole.stdout.contains("demo_len: raw: parameter of unmodeled pointer type *const i32"))
    let presented = p7_run(dir, "presented", "contract\0report\0c.demo\0demo_add\0")
    p7_assert_success(presented, "the contract of one presented function")
    assert(presented.stdout.contains(add_line) and not presented.stdout.contains("contract-audit"))
    p7_assert_failure_contains(p7_run(dir, "unknown", "contract\0report\0c.demo\0nope\0"), "has no line for `nope`", "a function the report does not list")
    p7_assert_failure_contains(p7_run(dir, "unfetched", "contract\0report\0c.other\0"), "run `with get c.other`", "a package with no fetched contract")
    print("ok")
