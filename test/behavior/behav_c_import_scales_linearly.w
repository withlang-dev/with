//! expect-stdout: ok

// c_import re-parsed the whole header once per object macro and scanned every
// declaration once per pointer type, so its cost was (macros + uses) x header:
// bzip2 and libcurl timed out on the Windows release legs, where each parse
// re-reads windows.h. Four times the declarations must cost about four times
// as long, not sixteen. A ratio, so the machine's speed cancels out.

use pre_d_build_runner
use std.time

fn check_seconds(case_dir: &str, decls: i32) -> f64:
    var header = StringBuilder.new()
    for i in 0..decls:
        header.push_str(f"typedef struct S{i} {{ struct S{i} *next; struct Op{i} *p; int v; }} S{i};\nS{i} *make{i}(struct Op{i} *o, int k);\n#define K{i} ({i} + 1)\n")
    p7_write(case_dir, f"src/big{decls}.h", header.to_str())
    p7_write(case_dir, f"src/use{decls}.w", f"use c_import(\"big{decls}.h\")\nfn main: print(f\"{{K7 + K9}}\")\n")
    let start = now_ns()
    let run = p7_run(case_dir, f"c_import of {decls} declarations", f"check\0src/use{decls}.w\0")
    p7_assert_success(run, f"c_import of {decls} declarations")
    (now_ns() - start) as f64 / 1000000000.0

fn main:
    let case_dir = p7_prepare_case("c_import_scales_linearly", "cimportscale")
    let small = check_seconds(case_dir, 750)
    let large = check_seconds(case_dir, 3000)
    // Linear is 4x; the old behavior measured 15x on these sizes.
    if large > small * 8.0 + 1.0:
        eprint(f"750 declarations: {small}s, 3000: {large}s")
        assert(false)
    print("ok")
