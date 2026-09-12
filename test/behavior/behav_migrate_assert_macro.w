//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_assert_macro", "assert_macro_test")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input.c", "#include <assert.h>\nstatic int failures;\nstatic void report(const char *text) { if (text[0]) ++failures; }\n#define CHECK(e) ((e) ? (void)0 : report(#e))\n#define STRING(s) #s\n#define XSTRING(s) STRING(s)\n#define NUMBER 37\nint check_macros(void) { int n = 0; CHECK(++n == 1); CHECK(++n == 0); assert(n == 2); return n + failures * 10; }\nconst char *expanded(void) { return XSTRING(NUMBER); }\nint fail_assert(void) { assert(0); return 99; }\n")
    let migrated = p7_run(case_dir, "assert_macro_migrate", "migrate\0input.c\0--no-c-export\0-o\0lib/assert_macro.w\0")
    p7_assert_success(migrated, "migrate assertion macros without stringifying their entire bodies")
    p7_write(case_dir, "src/main.w", "use assert_macro\nfn main:\n    assert(check_macros() == 12)\n    assert(unsafe { expanded()[0] } == 51)\n    assert(unsafe { expanded()[1] } == 55)\n    print(\"assert macros ok\")\n")
    let executed = p7_run(case_dir, "assert_macro_run", "run\0src/main.w\0")
    p7_assert_success(executed, "preserve assertion conditions, effects, and stringification wrappers")
    assert(executed.stdout.contains("assert macros ok"))
    p7_write(case_dir, "src/main.w", "use assert_macro\nfn main: fail_assert()\n")
    let failed = p7_run(case_dir, "assert_macro_fail", "run\0src/main.w\0")
    assert(failed.rc != 0)
    print("ok")
