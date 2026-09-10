//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_private_token_paste", "private_token_paste")
    // 1U pasted with LL is 64-bit on both LP64 and Windows LLP64.
    p7_write(case_dir, "input/SDKs/Fake.sdk/usr/include/suffix.h", "#define HOST_SUFFIX(v) (v ## LL)\n#define HOST_WRAPPER(v) HOST_SUFFIX(v)\n#define HOST_UNSIGNED(v) (v ## LL)\n")
    p7_write(case_dir, "input/unit.c", "#include \"SDKs/Fake.sdk/usr/include/suffix.h\"\n#define PROJECT_SHIFT(n) (HOST_WRAPPER(1) << (n))\n#define PROJECT_UNSIGNED(n) (HOST_UNSIGNED(1U) << (n))\n#define PROJECT_SUFFIX HOST_SUFFIX\nint value(void) { return PROJECT_SHIFT(3) == 8; }\n")
    let migrated = p7_run(case_dir, "private_token_paste_migrate", "migrate\0input\0--shared-defs\0sample.defs\0--no-c-export\0-o\0lib/sample\0")
    p7_assert_success(migrated, "migrate private token-paste dependencies")
    let defs = read_file(p7_join(case_dir, "lib/sample/defs.w")).unwrap()
    assert(not defs.contains("HOST_SUFFIX"))
    assert(not defs.contains("HOST_WRAPPER"))
    assert(not defs.contains("HOST_UNSIGNED"))
    assert(defs.contains("PROJECT_SHIFT"))
    assert(defs.contains("PROJECT_UNSIGNED"))
    assert(defs.contains("PROJECT_SUFFIX"))
    p7_write(case_dir, "src/main.w", "use sample.defs\nuse sample.unit\nfn main:\n    assert(PROJECT_SHIFT(3) == 8)\n    assert(PROJECT_UNSIGNED(63) == (1u64 << 63))\n    assert(PROJECT_SUFFIX(7) == 7i64)\n    assert(value() == 1)\n    print(\"pasted ok\")\n")
    let executed = p7_run(case_dir, "private_token_paste_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run project macros with private token-paste dependencies")
    assert(executed.stdout.contains("pasted ok"))
    print("ok")
