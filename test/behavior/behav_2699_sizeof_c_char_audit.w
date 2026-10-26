//! expect-stdout: ok

use pre_d_build_runner

// #2699: `audit:all` judged `sizeof[c_char]()` a disagreement ("owner=
// llvm-kind-8 derived=none"): the verification's AST derivation resolved
// `u8` but not an alias named in a type-level argument. A migrated engine
// takes `sizeof[c_char]()` (pcre2's match_), so every program a :dev stage1
// compiled from engine source failed the audit.
fn main:
    let case_dir = p7_prepare_case("sizeof_c_char_audit", "sizeofcchar")
    p7_write(case_dir, "src/sz.w", "use std.builtins.c_char\nfn main:\n    print(sizeof[c_char]() as i64 + sizeof[u8]() as i64)\n")
    let ran = p7_run(case_dir, "sz_run", "run\0src/sz.w\0")
    p7_assert_success(ran, "sizeof run")
    assert(ran.stdout.contains("2"))
    let audited = p7_run(case_dir, "sz_audit", "analyze\0src/sz.w\0audit:all\0")
    p7_assert_success(audited, "audit:all over sizeof[c_char]")
    assert(audited.stdout.contains("violations=0"))
    print("ok")
