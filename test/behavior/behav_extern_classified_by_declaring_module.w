//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process

// #1695: a module that declares `extern fn strerror` itself is classified by
// its own declaration whichever other module (std.fs) declares the same
// name, in either import order: the call needs `unsafe`, and a block that
// has it is not "an unsafe block without unsafe operations".
fn helper_src(with_unsafe: bool) -> str:
    let call = if with_unsafe: "unsafe { strerror(2) }" else: "strerror(2)"
    "extern fn strerror(errnum: i32) -> *mut i8\npub fn probe() -> i64:\n    let p = " ++ call ++ "\n    p as i64\n"

fn check_case(case_dir: &str, label: &str, uses: &str, with_unsafe: bool) -> P7Run:
    p7_write(case_dir, "src/helper.w", helper_src(with_unsafe))
    p7_write(case_dir, "src/main.w", uses ++ "fn main:\n    if probe() != 0: print(\"ok\")\n")
    p7_run(case_dir, label, "check\0src/main.w\0")

fn main:
    let case_dir = p7_prepare_case("extern_by_declaring_module", "externmod")
    let orders = ["use std.fs\nuse helper\n", "use helper\nuse std.fs\n"]
    for oi in 0..2:
        let uses = orders[oi]
        let good = check_case(case_dir, f"extern_mod_unsafe_{oi}", uses, true)
        p7_assert_success(good, f"extern_mod_unsafe_{oi}")
        let bad = check_case(case_dir, f"extern_mod_bare_{oi}", uses, false)
        assert(bad.rc != 0)
        assert(bad.stderr.contains("manual extern function call requires unsafe context"))
    print("ok")
