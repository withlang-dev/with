//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// A TU that only sees a record's forward declaration renders it as an
// incomplete type, and the TU that defines it completes the shared
// definition even when the incomplete TU sorts first.
fn main:
    let case_dir = p7_prepare_case("migrate_incomplete_record_order", "incomplete_record_order_test")
    p7_write(case_dir, "source/crate.h", "typedef struct _Crate Crate;\nCrate *crate_new(int value);\nint crate_value(Crate *box);\n")
    p7_write(case_dir, "source/probe.c", "#include \"crate.h\"\nint probe(void) { Crate *box = crate_new(41); return crate_value(box) + 1; }\n")
    p7_write(case_dir, "source/zcrate.c", "#include <stdlib.h>\n#include \"crate.h\"\nstruct _Crate { int value; };\nCrate *crate_new(int value) { Crate *box = malloc(sizeof(Crate)); box->value = value; return box; }\nint crate_value(Crate *box) { return box->value; }\n")
    let migrated = p7_run(case_dir, "incomplete_record_migrate", "migrate\0source\0--no-c-export\0-I\0source\0--shared-defs\0probe.defs\0-o\0lib/probe\0")
    p7_assert_success(migrated, "migrate a record whose definition follows its incomplete use")
    let defs = read_file(p7_join(case_dir, "lib/probe/defs.w")).unwrap()
    assert(defs.contains("type _Crate { value: c_int = 0 }"))
    assert(not defs.contains("__pad0"))
    p7_write(case_dir, "src/main.w", "use probe.probe\nfn main: assert(probe() == 42)\n")
    let executed = p7_run(case_dir, "incomplete_record_run", "run\0src/main.w\0")
    p7_assert_success(executed, "read through the completed record definition")
    print("ok")
