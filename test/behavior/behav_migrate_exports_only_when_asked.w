//! expect-stdout: ok

// `with migrate` writes With functions. Exporting them under their C names
// is spelled `--c-export`, by whoever still has C calling them (Eric,
// 2026-10-04): it was the default, which every corpus and nearly every test
// had to opt out of. With no flag, a struct passed by value migrates, checks
// and runs (#2119: the default output held a `@[c_export]` the compiler
// rejects).

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("migrate_exports_only_when_asked", "migrateexports")
    p7_write(case_dir, "tiny.c", "#define SCALE 2\nstruct Pair { int a; int b; };\nint add_pair(struct Pair p) {\n    return (p.a + p.b) * SCALE;\n}\nint twice(int x) { return x * SCALE; }\nint main(void) {\n    struct Pair p = { 20, 1 };\n    return add_pair(p) == 42 && twice(4) == 8 ? 0 : 1;\n}\n")
    let plain = p7_run(case_dir, "migrate (default)", "migrate\0tiny.c\0-o\0plain.w\0")
    p7_assert_success(&plain, "migrate (default)")
    let plain_text = read_file(case_dir ++ "/plain.w").unwrap()
    assert(not plain_text.contains("@[c_export("), "the default exports nothing")
    assert(plain_text.contains("fn add_pair"))
    let ran = p7_run(case_dir, "run the default output", "run\0plain.w\0")
    p7_assert_success(&ran, "run the default output")

    let spelled = p7_run(case_dir, "migrate --no-c-export", "migrate\0tiny.c\0-o\0spelled.w\0--no-c-export\0")
    p7_assert_success(&spelled, "migrate --no-c-export")
    assert(read_file(case_dir ++ "/spelled.w").unwrap() == plain_text, "--no-c-export is the default")

    let exported = p7_run(case_dir, "migrate --c-export", "migrate\0tiny.c\0-o\0exported.w\0--c-export\0")
    p7_assert_success(&exported, "migrate --c-export")
    assert(read_file(case_dir ++ "/exported.w").unwrap().contains("@[c_export(\"twice\")]"), "--c-export exports under the C name")
    print("ok")
