//! expect-stdout: ok

// #1372: a root module and a module it imports each `use c_import(...)`.
// The frontend emits a C declaration shared by both headers once, into the
// first importer's expansion (cu.w's <stdio.h> declares `c_ulonglong`,
// `c_uint`, `_opaque_pthread_attr_t`, ...), and the root's <stdlib.h>
// expansion names them. Value lookup already let a module that uses
// c_import see the program's C declarations (is_ci_visible); type lookup
// applied module privacy instead, and the root failed with 825 errors —
// "'c_uint' requires an explicit import", "symbol '_opaque_pthread_attr_t'
// is private to module 'cu.w'". A module that uses no c_import still sees
// none of them.
//
// The programs run from src/ and are named bare: module privacy is enforced
// then, and not when the entry is spelled `src/m.w` (#1520).
use pre_d_build_runner

fn main:
    let case_dir = p7_prepare_case("two_modules_c_import", "two_modules_c_import")
    p7_write(case_dir, "src/cu.w", "use c_import(\"<stdio.h>\")\npub fn greet() -> str: \"hi\"\n")
    p7_write(case_dir, "src/m.w", "use cu\nuse c_import(\"<stdlib.h>\")\nfn main:\n    print(greet())\n    print(f\"{abs(-3)} {atoi(\"42\")}\")\n")
    p7_write(case_dir, "src/plain.w", "use cu\nfn main:\n    let n: c_uint = 3\n    print(f\"{n} {greet()}\")\n")
    let src_dir = p7_join(case_dir, "src")
    let ran = p7_run(src_dir, "two_modules_run", "run\0m.w\0")
    p7_assert_success(ran, "root and imported module each use c_import")
    assert(ran.stdout.contains("hi\n3 42"))

    // The imported module's C declarations stay invisible to a module that
    // does not use c_import.
    let plain = p7_run(src_dir, "plain_module_run", "run\0plain.w\0")
    assert(plain.rc != 0)
    assert((plain.stdout ++ plain.stderr).contains("c_uint"))
    print("ok")
