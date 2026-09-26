//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process

// §18.2 name precedence (#1703): a name reaches a module only through that
// module's own `use` (tier 3), the prelude (4) or the std fallback (5) —
// never through what an imported module imported. And a lexical binding
// (tier 1) shadows an imported global instead of being refused.
fn main:
    let case_dir = p7_prepare_case("imports_not_transitive", "importvis")
    p7_write(case_dir, "src/helper2.w", "pub let PACKAGE = \"x\"\npub fn deep() -> i32: 1\n")
    p7_write(case_dir, "src/helper.w", "use helper2\npub fn helper_used() -> i32: deep()\n")
    // main imports helper only: helper2's `deep` is not in scope.
    p7_write(case_dir, "src/main.w", "use helper\nfn main:\n    print(deep())\n")
    let leak = p7_run(case_dir, "imports_transitive_fn", "check\0src/main.w\0")
    assert(leak.rc != 0)
    assert(leak.stderr.contains("deep"))
    // A local named like helper2's global, reached directly or not, is the
    // local (tier 1 over tier 3).
    p7_write(case_dir, "src/main.w", "use helper2\nfn main:\n    let PACKAGE = 2\n    print(PACKAGE + deep())\n")
    let local_wins = p7_run(case_dir, "imports_local_shadows", "run\0src/main.w\0")
    p7_assert_success(local_wins, "imports_local_shadows")
    assert(local_wins.stdout.contains("3"))
    print("ok")
