//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// A pointer to a system-header record with a reserved tag (Darwin's
// `struct __sFILE`, glibc's `_IO_FILE`, the UCRT's `_iobuf`: what `FILE *`
// is) has no With spelling: the migrator never emits system records, and
// std.libc's fopen/fprintf take `*mut c_void`. The parameter must be
// `*mut c_void`, so the migrated function accepts fopen's result and
// compiles on every host. A project's own reserved-spelled tag keeps its
// identity. (#1142 spelled the tag and the corpora stopped compiling.)
// Every position is one rule: parameter, field and return, and inside a
// body a local, an initialised local and a cast (the body's type builder
// spelled the tag after the signature's stopped, and minigzip broke).
fn main:
    let case_dir = p7_prepare_case("migrate_system_record_pointer", "system_record_pointer_test")
    p7_write(case_dir, "source/node.h", "typedef struct _ProjNode { int value; struct _ProjNode *next; } ProjNode;\n")
    p7_write(case_dir, "source/unit.c", "#include <stdio.h>\n#include \"node.h\"\nint count_to(FILE *out, ProjNode *node) { int n = 0; while (node) { n += node->value; node = node->next; } if (out) fprintf(out, \"%d\\n\", n); return n; }\nint opens(const char *p) { FILE *in; FILE *again = fopen(p, \"rb\"); in = again; if (in == NULL) return 0; fclose(in); return 1; }\nint failed(void *s) { return ferror((FILE *)s); }\nFILE *reopen(const char *p) { return fopen(p, \"rb\"); }\nstruct holder { FILE *f; };\n")
    let migrated = p7_run(case_dir, "system_record_migrate", "migrate\0source\0--no-c-export\0-I\0source\0--shared-defs\0sr.defs\0-o\0lib/sr\0")
    p7_assert_success(migrated, "migrate a FILE pointer parameter")
    let unit = read_file(p7_join(case_dir, "lib/sr/unit.w")).unwrap()
    let defs = read_file(p7_join(case_dir, "lib/sr/defs.w")).unwrap()
    assert(unit.contains("__param_out: *mut c_void"))
    assert(not unit.contains("__sFILE") and not unit.contains("_IO_FILE") and not unit.contains("_iobuf"))
    assert(unit.contains("*mut _ProjNode"))
    assert(defs.contains("pub type _ProjNode"))
    p7_write(case_dir, "src/main.w", "use sr.unit\nuse sr.defs\nfn main:\n    var b = _ProjNode { value: 3, next: null }\n    var a = _ProjNode { value: 4, next: &raw mut b }\n    unsafe { assert(count_to(null, &raw mut a) == 7) }\n    unsafe { assert(opens(c\"/no/such/file\".ptr) == 0) }\n")
    let executed = p7_run(case_dir, "system_record_run", "run\0src/main.w\0")
    p7_assert_success(executed, "call the migrated function with a null stream")
    print("ok")
