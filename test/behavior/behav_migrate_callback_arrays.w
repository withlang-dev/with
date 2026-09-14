//! expect-stdout: ok

use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("migrate_callback_arrays", "migrate_callback_arrays_test")
    p7_write(case_dir, "input/source.c", "#include <stdlib.h>\n#include <string.h>\ntypedef int (*Convert)(const char *);\nConvert callbacks[] = {atoi, atoi, 0};\nstruct Holder { Convert call; };\nstatic int invoke(Convert call, const char *text) { return call(text); }\nint verify(void) { struct Holder holder = {atoi}; int sum = 0; for (int i = 0; callbacks[i] != 0; ++i) sum += callbacks[i](\"21\"); return sum == 42 && holder.call(\"13\") == 13 && invoke(atoi, \"7\") == 7 && strcmp(\"same\", \"same\") == 0; }\n")
    p7_write(case_dir, "lib/std/callbacks/.keep", "")
    let migrated = p7_run(case_dir, "callback_arrays_migrate", "migrate\0input\0--no-c-export\0--shared-defs\0std.callbacks.defs\0-o\0lib/std/callbacks\0")
    p7_assert_success(migrated, "migrate callback arrays and nested callback signatures")
    p7_write(case_dir, "src/main.w", "use std.callbacks.source\nfn main: assert(verify() == 1)\n")
    let executed = p7_run(case_dir, "callback_arrays_run", "run\0src/main.w\0")
    p7_assert_success(executed, "preserve null sentinel, callback argument conversions, and std extern policy")
    print("ok")
