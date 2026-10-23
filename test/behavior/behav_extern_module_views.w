//! expect-stdout: ok

use pre_d_build_runner
use std.fs

// An extern declaration is its module's view of a C symbol, as a C
// prototype is a translation unit's: two modules may spell `strlen`'s
// result differently (an older migrated corpus says `i64`, a newer one
// `u64`, C says `size_t`) and each calls it through its own signature;
// codegen declares the symbol once. Nothing in the tree has to agree with
// anything else about a C declaration (D112: 20,000 corpora).
fn main:
    let case_dir = p7_prepare_case("extern_module_views", "extern_module_views_test")
    p7_write(case_dir, "lib/views/old_gen.w", "module views.old_gen\nextern fn strlen(s: *const i8) -> i64\npub fn old_len(s: *const i8) -> i64: unsafe { strlen(s) }\n")
    p7_write(case_dir, "lib/views/new_gen.w", "module views.new_gen\nextern fn strlen(s: *const i8) -> u64\npub fn new_len(s: *const i8) -> u64: unsafe { strlen(s) }\n")
    p7_write(case_dir, "src/main.w", "use views.old_gen\nuse views.new_gen\nfn main:\n    let text = c\"seven_7\"\n    let a = old_len(text.ptr)\n    let b = new_len(text.ptr)\n    assert(a == 7 and b == 7)\n")
    let executed = p7_run(case_dir, "extern_views_run", "run\0src/main.w\0")
    p7_assert_success(executed, "two modules' views of one C symbol")
    print("ok")
