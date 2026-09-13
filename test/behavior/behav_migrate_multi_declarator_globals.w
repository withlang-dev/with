//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("migrate_multi_declarator_globals", "migrate_multi_declarator_globals_test")
    p7_write(case_dir, "input.c", "int first = 50, second, third = 72, fourth;\nint values[3], filled[3] = {1, 2, 3}, more[2];\nint *address = &first, *empty;\nint verify(void) { return first == 50 && second == 0 && third == 72 && fourth == 0 && values[2] == 0 && filled[2] == 3 && more[1] == 0 && *address == 50 && empty == 0; }\n")
    let migrated = p7_run(case_dir, "multi_declarator_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/globals.w\0")
    p7_assert_success(migrated, "classify and lower each declarator's own initializer")
    p7_write(case_dir, "src/main.w", "use globals\nfn main: assert(verify() == 1)\n")
    let executed = p7_run(case_dir, "multi_declarator_run", "run\0src/main.w\0")
    p7_assert_success(executed, "preserve explicit initializers and C tentative zero initialization")
    print("ok")
