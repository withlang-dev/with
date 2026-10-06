//! expect-stdout: ok

use pre_d_build_runner

// §18.3 (D100): privacy is a property of the packages, not of the spelling
// of the entry path (#1520: a project laid out as `src/a.w`, `src/b.w` had
// privacy only when checked from inside `src/`). Without `pub`, a
// declaration is visible throughout its package and refused from another:
// `src/dep` has its own with.toml, so its private `Secret` is refused to
// the program's modules, while the program's own modules read each other's
// private declarations. A module's C declarations are an import, visible
// only to a module that uses c_import itself (`c_uint`), in either package.
fn main:
    let case_dir = p7_prepare_case("module_privacy_under_src_dir", "privsrc")
    p7_write(case_dir, "src/dep/with.toml", "[package]\nname = \"dep\"\n")
    p7_write(case_dir, "src/dep/cu.w", "use c_import(\"<stdio.h>\")
type Secret = i32
pub fn greet() -> str: \"hi\"
")
    p7_write(case_dir, "src/p1.w", "use dep.cu
fn main:
    let s: Secret = 3
    print(f\"{s} {greet()}\")
")
    p7_write(case_dir, "src/p2.w", "use dep.cu
fn main:
    let n: c_uint = 3
    print(f\"{n} {greet()}\")
")
    p7_write(case_dir, "src/p3.w", "use dep.cu
fn main:
    print(greet())
")
    let private_type = p7_run(case_dir, "privacy-src-dir-type", "check\0src/p1.w\0")
    p7_assert_failure_contains(private_type, "symbol 'Secret' is private to its package", "check src/p1.w")
    let private_c = p7_run(case_dir, "privacy-src-dir-c", "check\0src/p2.w\0")
    p7_assert_failure_contains(private_c, "'c_uint' requires an explicit import", "check src/p2.w")
    let public_ok = p7_run(case_dir, "privacy-src-dir-pub", "check\0src/p3.w\0")
    p7_assert_success(public_ok, "check src/p3.w")
    // An impl on another package's private type names the cause at the impl
    // header, not as "unknown method … for type '&<error>'" at each use.
    p7_write(case_dir, "src/p4.w", "use dep.cu
impl Secret:
    fn twice() -> i32: *self * 2
fn main:
    print(greet())
")
    let private_impl = p7_run(case_dir, "privacy-src-dir-impl", "check\0src/p4.w\0")
    p7_assert_failure_contains(private_impl, "symbol 'Secret' is private to its package", "check src/p4.w")
    // Within one package, no `pub` is needed (D100).
    p7_write(case_dir, "src/mine.w", "type Mine = i32
fn seven() -> Mine: 7
")
    p7_write(case_dir, "src/p5.w", "use mine
fn main:
    let m: Mine = seven()
    print(f\"{m}\")
")
    let same_package = p7_run(case_dir, "privacy-src-dir-same-package", "check\0src/p5.w\0")
    p7_assert_success(same_package, "check src/p5.w")
    print("ok")
