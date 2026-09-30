//! expect-stdout: ok

// #1933: the migrator's preamble helpers (`__with_builtin_add_overflow_i32(a,
// b, out)`, `is_alpha(c)`) share a module with the C program's globals, so a
// C global named `a`, `b`, `c` or `out` made each helper parameter a refused
// shadow and the migrated file did not compile.
use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_helper_hygiene", "helper_hygiene_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", "int a = 1, b = 2, c = 3, out = 4, result = 5;\nint sum(void) { int r; if (__builtin_add_overflow(a, b, &r)) return -1; return r + c + out + result; }\n")
    let migrated = p7_run(case_dir, "helper_hygiene_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/hygiene.w\0")
    p7_assert_success(migrated, "migrate a file whose globals share the helpers' parameter names")
    p7_write(case_dir, "src/main.w", "use hygiene\nfn main:\n    assert(sum() == 15)\n    print(\"hygiene ok\")\n")
    let executed = p7_run(case_dir, "helper_hygiene_run", "run\0src/main.w\0")
    p7_assert_success(executed, "compile and run the migrated globals beside the helpers")
    assert(executed.stdout.contains("hygiene ok"))
    print("ok")
