//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_empty_statements", "empty_statements_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", "int count(void) { int i = 0; for (; i < 5; ++i) ; while (i++ < 8) ; do ; while (i++ < 10); if (i++) ; else ; return i; }\n")
    let migrated = p7_run(case_dir, "empty_statements_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/empty_statements.w\0")
    p7_assert_success(migrated, "migrate empty loop bodies and conditional arms")
    p7_write(case_dir, "src/main.w", "use empty_statements\nfn main:\n    assert(count() == 12)\n    print(\"empty statements ok\")\n")
    let executed = p7_run(case_dir, "empty_statements_run", "run\0src/main.w\0")
    p7_assert_success(executed, "preserve condition and increment effects around empty statements")
    assert(executed.stdout.contains("empty statements ok"))
    print("ok")
