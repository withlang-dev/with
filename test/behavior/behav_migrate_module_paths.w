//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_module_paths", "module_paths_test")
    p7_write(case_dir, "source/a-b.c", "int answer(void) { return 42; }\n")
    p7_write(case_dir, "source/if.c", "int answer(void); int result(void) { return answer(); }\n")
    let migrated = p7_run(case_dir, "module_paths_migrate", "migrate\0source\0--no-c-export\0--shared-defs\0probe.defs\0-o\0lib/probe\0")
    p7_assert_success(migrated, "normalize module paths and imports together")
    p7_write(case_dir, "src/main.w", "use probe.if_\nfn main:\n    assert(result() == 42)\n    print(\"module paths ok\")\n")
    let executed = p7_run(case_dir, "module_paths_run", "run\0src/main.w\0")
    p7_assert_success(executed, "run cross-module calls through normalized paths")
    assert(executed.stdout.contains("module paths ok"))
    p7_write(case_dir, "source/a_b.c", "int distinct(void) { return 7; }\n")
    let collision = p7_run(case_dir, "module_paths_collision", "migrate\0source\0--no-c-export\0--shared-defs\0probe.defs\0-o\0lib/collision\0")
    p7_assert_failure_contains(collision, "module path collision", "reject collisions before overwriting a module")
    assert(not file_exists(p7_join(case_dir, "lib/collision/a_b.w")))
    print("ok")
