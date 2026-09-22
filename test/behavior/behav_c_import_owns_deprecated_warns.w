//! expect-stdout: ok

use pre_d_build_runner

// D51 stage 4c: the plan says `owns:`/`borrows:` "become deprecated spellings
// with a diagnostic naming the facade clause". `with check` accepts them
// (behav_c_import_owns_borrows_deprecated.w runs the program) and warns,
// naming the facade clauses to write instead.
fn main:
    let case_dir = p7_prepare_case("owns_deprecated_warns", "ownswarn")
    p7_write(case_dir, "main.w", "use c_import(\"char *cwd_owned(void);\\nvoid free(void *p);\\ntypedef struct __dirstream DIR;\\nDIR *opendir(const char *name);\\nlong telldir(DIR *dirp);\\nint closedir(DIR *dirp);\\n\", owns: [\"cwd_owned -> free\"], borrows: [\"telldir(0) -> opendir\"])\n\nfn main:\n    print(\"ok\")\n")
    let checked = p7_run(case_dir, "owns-warn", "check\0main.w\0")
    p7_assert_success(checked, "with check")
    assert(checked.stderr.contains("owns: \"cwd_owned -> free\" is a deprecated spelling of a facade resource"))
    assert(checked.stderr.contains("`resource CwdOwned wraps *mut i8` / `from cwd_owned` / `drop free`"))
    assert(checked.stderr.contains("borrows: \"telldir(0) -> opendir\" is a deprecated spelling of a facade lend"))
    assert(checked.stderr.contains("`fn telldir` / `lend`"))
    print("ok")
