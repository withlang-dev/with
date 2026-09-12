//! expect-stdout: ok

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_embedded_header_origins", "embedded_header_origins")
    assert(mkdir_p(p7_join(case_dir, "lib")) == 0)
    p7_write(case_dir, "input/unit.c", "#undef NULL\n#include <__stddef_null.h>\n#define PROJECT_NULL NULL\nint is_null(void *value) { return value == NULL; }\n")
    let migrated = p7_run(case_dir, "embedded_header_migrate", "migrate\0input\0--shared-defs\0sample.defs\0--no-c-export\0-o\0lib/sample\0")
    p7_assert_success(migrated, "filter materialized builtin header declarations")
    let source = read_file(p7_join(case_dir, "lib/sample/defs.w")).unwrap()
    assert(not source.contains("let NULL:"))
    assert(source.contains("PROJECT_NULL"))
    p7_write(case_dir, "src/main.w", "use sample.unit\nuse sample.defs\nfn main:\n    assert(PROJECT_NULL == null)\n    unsafe { assert(is_null(null) == 1) }\n    print(\"project ok\")\n")
    let executed = p7_run(case_dir, "embedded_header_run", "run\0src/main.w\0")
    p7_assert_success(executed, "execute project aliases of builtin macros")
    assert(executed.stdout.contains("project ok"))
    print("ok")
