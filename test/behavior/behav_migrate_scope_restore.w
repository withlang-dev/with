//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_scope_restore", "scope_restore_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", "int restored(int data) { int total = data; { int data = 7; total += data; { long data = 11; total += data; } total += data; } total += data; return total; }\n")
    let migrated = p7_run(case_dir, "scope_restore_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/scope_restore.w\0")
    p7_assert_success(migrated, "restore nested names and types after shadowing")
    let output = read_file(p7_join(case_dir, "lib/scope_restore.w"))
    assert(not output.contains("\0"))
    p7_write(case_dir, "src/main.w", "use scope_restore\nfn main:\n    assert(restored(3) == 31)\n    assert(restored(13) == 51)\n    print(\"scope restore ok\")\n")
    let executed = p7_run(case_dir, "scope_restore_run", "run\0src/main.w\0")
    p7_assert_success(executed, "execute restored bindings with distinct input values")
    assert(executed.stdout.contains("scope restore ok"))
    print("ok")
