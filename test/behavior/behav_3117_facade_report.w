//! expect-stdout: ok

use pre_d_build_runner

// #3117: a call of a function the fetched package's facade leaves raw
// quotes the report's reason and names the report `with get` wrote beside
// the facade.
fn main:
    let dir = p7_prepare_case("3117_facade_report", "facade_report")
    p7_write(dir, "with.toml", "[package]\nname = \"facade_report\"\nversion = \"0.1.0\"\n\n[deps]\nc.demo = \"1.0\"\n")
    p7_write(dir, ".with/deps/c/demo/1.0/metadata.json", "{\n  \"name\": \"demo\",\n  \"version\": \"1.0\",\n  \"include_paths\": [\"include\"],\n  \"lib_paths\": [],\n  \"libs\": [],\n  \"defines\": [],\n  \"link_args\": [],\n  \"components\": []\n}\n")
    p7_write(dir, ".with/deps/c/demo/1.0/include/demo.h", "static inline char *demo_version(void) { static char out[8]; out[0] = 'v'; return out; }\nstatic inline int demo_add(int a, int b) { return a + b; }\n")
    p7_write(dir, ".with/deps/c/demo/1.0/facade.w", "use c_import(\"demo.h\")\n\nc facade demo:\n    fn demo_add\n")
    p7_write(dir, ".with/deps/c/demo/1.0/facade-report.txt", "facade demo: 2 functions, 1 presented safely, 1 raw\n  demo_add: value-only call\n  demo_version: raw: returns *mut c_char, a pointer to no record\n")
    p7_write(dir, "src/main.w", "use c_import(\"demo.h\")\n\nfn main:\n    let v = demo_version()\n    print(f\"{demo_add(1, 2)}\")\n")
    p7_assert_failure_contains(p7_run(dir, "raw", "check\0src/main.w\0"), "the facade of demo leaves `demo_version` raw: returns *mut c_char, a pointer to no record (", "a raw call names its report line")

    p7_assert_failure_contains(p7_run(dir, "raw-path", "check\0src/main.w\0"), ".with/deps/c/demo/1.0/facade-report.txt)", "the note names the report file")
    print("ok")
