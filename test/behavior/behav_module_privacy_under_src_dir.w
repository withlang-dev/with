//! expect-stdout: ok

use pre_d_build_runner

// #1520 (§18.3): privacy is a property of the modules, not of the spelling
// of the entry path. A project laid out as `src/a.w`, `src/b.w` had privacy
// only when checked from inside `src/`: every path under a `src/`, `build/`
// or `rt/` directory counted as the compiler's own tree, and such modules
// read each other's private declarations — including a module's private
// C declarations (`c_uint` with no c_import of its own).
fn main:
    let case_dir = p7_prepare_case("module_privacy_under_src_dir", "privsrc")
    p7_write(case_dir, "src/cu.w", "use c_import(\"<stdio.h>\")
type Secret = i32
pub fn greet() -> str: \"hi\"
")
    p7_write(case_dir, "src/p1.w", "use cu
fn main:
    let s: Secret = 3
    print(f\"{s} {greet()}\")
")
    p7_write(case_dir, "src/p2.w", "use cu
fn main:
    let n: c_uint = 3
    print(f\"{n} {greet()}\")
")
    p7_write(case_dir, "src/p3.w", "use cu
fn main:
    print(greet())
")
    let private_type = p7_run(case_dir, "privacy-src-dir-type", "check\0src/p1.w\0")
    p7_assert_failure_contains(private_type, "symbol 'Secret' is private to module", "check src/p1.w")
    let private_c = p7_run(case_dir, "privacy-src-dir-c", "check\0src/p2.w\0")
    p7_assert_failure_contains(private_c, "'c_uint' requires an explicit import", "check src/p2.w")
    let public_ok = p7_run(case_dir, "privacy-src-dir-pub", "check\0src/p3.w\0")
    p7_assert_success(public_ok, "check src/p3.w")
    print("ok")
