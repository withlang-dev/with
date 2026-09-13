//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("migrate_null_callback", "migrate_null_callback_test")
    p7_write(case_dir, "input.c", "#include <stddef.h>\ntypedef void (*Test)(void);\nstatic int calls;\nvoid count(void) { ++calls; }\nTest tests[] = {count, NULL};\nvoid invoke(Test f) { f(); }\nint verify(void) { for (int i = 0; tests[i] != NULL; ++i) invoke(tests[i]); return calls; }\n")
    p7_write(case_dir, "lib/.keep", "")
    let migrated = p7_run(case_dir, "null_callback_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/converted.w\0")
    p7_assert_success(migrated, "migrate macro null sentinels and value-only callbacks")
    p7_write(case_dir, "src/main.w", "use converted\nfn main: assert(verify() == 1)\n")
    let executed = p7_run(case_dir, "null_callback_run", "run\0src/main.w\0")
    p7_assert_success(executed, "invoke stored callback values with their declared safety contract")
    print("ok")
