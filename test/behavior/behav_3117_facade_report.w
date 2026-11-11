//! expect-stdout: ok

use pre_d_build_runner

// #3117: a call of a function the fetched package's facade leaves raw
// quotes the report's reason and names the command that prints it, and
// `with facade report c.<package> [function]` prints the report `with get`
// wrote beside the facade.
fn main:
    let dir = p7_prepare_case("3117_facade_report", "facade_report")
    p7_write(dir, "with.toml", "[package]\nname = \"facade_report\"\nversion = \"0.1.0\"\n\n[deps]\nc.demo = \"1.0\"\n")
    p7_write(dir, ".with/deps/c/demo/1.0/metadata.json", "{\n  \"name\": \"demo\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": [],\n  \"defines\": [],\n  \"link_args\": [],\n  \"components\": []\n}\n")
    p7_write(dir, ".with/deps/c/demo/1.0/include/demo.h", "static inline char *demo_version(void) { static char out[8]; out[0] = 'v'; return out; }\nstatic inline int demo_add(int a, int b) { return a + b; }\n")
    p7_write(dir, ".with/deps/c/demo/1.0/facade.w", "use c_import(\"demo.h\")\n\nc facade demo:\n    fn demo_add\n")
    p7_write(dir, ".with/deps/c/demo/1.0/facade-report.txt", "facade demo: 2 functions, 1 presented safely, 1 raw\n  demo_add: value-only call\n  demo_version: raw: returns *mut c_char, a pointer to no record\n")
    p7_write(dir, "src/main.w", "use c_import(\"demo.h\")\n\nfn main:\n    let v = demo_version()\n    print(f\"{demo_add(1, 2)}\")\n")
    p7_assert_failure_contains(p7_run(dir, "raw", "check\0src/main.w\0"), "the facade of demo leaves `demo_version` raw: returns *mut c_char, a pointer to no record (`with facade report c.demo demo_version`)", "a raw call names its report line")

    let one = p7_run(dir, "one", "facade\0report\0c.demo\0demo_version\0")
    p7_assert_success(one, "the report of one function")
    assert(one.stdout.trim() == "demo_version: raw: returns *mut c_char, a pointer to no record")
    let whole = p7_run(dir, "whole", "facade\0report\0c.demo\0")
    p7_assert_success(whole, "the whole report")
    assert(whole.stdout.contains("facade demo: 2 functions, 1 presented safely, 1 raw") and whole.stdout.contains("  demo_add: value-only call"))
    p7_assert_failure_contains(p7_run(dir, "unknown", "facade\0report\0c.demo\0nope\0"), "has no line for `nope`", "a function the report does not list")
    p7_assert_failure_contains(p7_run(dir, "unfetched", "facade\0report\0c.other\0"), "run `with get c.other`", "a package with no fetched facade")
    print("ok")
