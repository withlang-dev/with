//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

use pre_d_build_runner

// What a new user sees in their first ten seconds. `with run` prints the
// program's output: no build timing report ("[time] spiral 0.3s", "[times]
// total ..."), which `with build` still gives. And a c_imported struct larger
// than copy_warn_threshold is the header's, not the user's: it is Copy because
// a C struct copies, so it gets no "large Copy type" warning (raylib's Model
// and VrStereoConfig greeted every first raylib program with two); the user's
// own large Copy type still does.
fn main:
    let case_dir = p7_prepare_case("user_run_is_quiet", "quietrun")
    // The project `with init` writes: an executable default target.
    p7_write(case_dir, "build.w", "use std.build\n\ncomptime with BuildCtx as ctx:\npub fn build -> Build:\n    var out = ctx.new_build().executable(\"quietrun\", \"src/main.w\")\n    out.default(\"quietrun\")\n")
    p7_write(case_dir, "src/big.h", "typedef struct Big { double cells[40]; } Big;\n")
    p7_write(case_dir, "src/main.w", "use c_import(\"big.h\")\n\ntype Mine { a: [40]f64 }\nimpl Copy for Mine\n\nfn main:\n    print(\"hello from the program\")\n")

    let ran = p7_run(case_dir, "quiet-run", "run\0")
    p7_assert_success(ran, "with run")
    assert(ran.stdout.contains("hello from the program"))
    assert(not ran.stderr.contains("[time]") and not ran.stderr.contains("[times]"))
    assert(not ran.stdout.contains("[time]") and not ran.stdout.contains("[times]"))
    assert(not ran.stderr.contains("large Copy type 'Big'"))
    assert(ran.stderr.contains("large Copy type 'Mine'"))

    // A build is where the timing report belongs. Touch the source so there
    // is something to time.
    p7_write(case_dir, "src/main.w", "use c_import(\"big.h\")\n\nfn main:\n    print(\"hello again\")\n")
    let built = p7_run(case_dir, "quiet-build", p7_build_args())
    p7_assert_success(built, "with build")
    assert(built.stderr.contains("[time]"))
    print("ok")
