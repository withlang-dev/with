//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// `with fix-contracts` respells the old keyword and the old module path
// where they are code, and leaves the word alone in a string, a comment and
// a name: "facade" also means the library layer over a migrated engine.
fn main:
    let dir = p7_prepare_case("wcl_fix_contracts", "fix_contracts")
    let old = "use " ++ "facades.other\n\n// a c " ++ "facade in a comment stays\nc " ++ "facade h:\n    fn h_get\n\nfn main:\n    let facade = \"c " ++ "facade x:\"\n    print(facade)\n"
    p7_write(dir, "src/old.w", old)
    let listed = p7_run(dir, "list", "fix-contracts\0src/old.w\0")
    p7_assert_success(listed, "listing")
    assert(listed.stdout.contains("src/old.w:1: facades -> contracts") and listed.stdout.contains("src/old.w:4: facade -> contract") and listed.stdout.contains("2 to respell"))
    assert((read_file(p7_join(dir, "src/old.w")) ?? "") == old)
    p7_assert_success(p7_run(dir, "apply", "fix-contracts\0--apply\0src/old.w\0"), "applying")
    let now = (read_file(p7_join(dir, "src/old.w")) ?? "")
    let want = "use contracts.other\n\n// a c " ++ "facade in a comment stays\nc contract h:\n    fn h_get\n\nfn main:\n    let facade = \"c " ++ "facade x:\"\n    print(facade)\n"
    if now != want: print(now)
    assert(now == want)
    let again = p7_run(dir, "again", "fix-contracts\0src/old.w\0")
    assert(again.stdout.contains("0 to respell"))
    print("ok")
