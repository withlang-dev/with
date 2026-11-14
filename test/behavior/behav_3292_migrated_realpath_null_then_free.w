//! expect-stdout: ok
//! skip-on: windows no realpath on Windows
// #3292: `with migrate` rewrites `free` to the runtime's allocator, on the
// assumption that every allocation of the program is translated with it.
// `realpath(path, NULL)` broke it: libc allocated the result with malloc,
// and the migrated `free(p)` panicked "invalid free". std.libc's realpath
// now resolves into a buffer the runtime allocated.
use std.fs
use pre_d_build_runner

fn main:
    let root = p7_prepare_case("migrated_realpath_null_then_free", "realpathfree")
    p7_write(root, "realpath.c", "#include <stdlib.h>\n#include <stdio.h>\nint main(void) { char *p = realpath(\".\", NULL); printf(\"%d\\n\", p != 0 && p[0] == '/'); free(p); return 0; }\n")
    let migrated = p7_run(root, "migrate", p7_argv_append(p7_argv_append(p7_argv_append(p7_argv_append("", "migrate"), "realpath.c"), "-o"), "realpath.w"))
    p7_assert_success(migrated, "with migrate realpath.c")
    let ran = p7_run(root, "run", p7_argv_append(p7_argv_append("", "run"), "realpath.w"))
    p7_assert_success(ran, "the migrated program")
    assert(ran.stdout.contains("1"))
    print("ok")
