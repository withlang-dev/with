//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("migrate_atoi", "migrate_atoi_test")
    p7_write(case_dir, "input.c", "#include <stdlib.h>\nint verify(void) { int (*convert)(const char *) = atoi; return atoi(\" -37tail\") == -37 && convert(\"42\") == 42 && atoi(\"no digits\") == 0; }\n")
    p7_write(case_dir, "lib/.keep", "")
    let migrated = p7_run(case_dir, "atoi_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/converted.w\0")
    p7_assert_success(migrated, "resolve direct and function-pointer atoi references through std.libc")
    p7_write(case_dir, "src/main.w", "use converted\nfn main: assert(verify() == 1)\n")
    let executed = p7_run(case_dir, "atoi_run", "run\0src/main.w\0")
    p7_assert_success(executed, "preserve libc integer conversion semantics")
    print("ok")
