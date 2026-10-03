//! only-on: windows
//! env: HOME=
//! expect-stdout: ok

// #1884: cmd.exe and PowerShell set no HOME. An install destination under
// `$HOME/` then resolves through %USERPROFILE% (build_graph_home_dir), as
// build/wo.w's store does (wo_home, #1915), instead of landing at
// `/.local/...` and being refused as an escape. The runner empties HOME for
// this test (an empty HOME reads as unset: env_input gives "").
use pre_d_build_runner
use std.fs
use std.process

fn main:
    assert(env("HOME").len() == 0)
    let profile = env("USERPROFILE")
    assert(profile.len() > 0)
    let case_dir = p7_prepare_case("build_1884_home_unset", "homeunset")
    var build_text = "use std.build\n\n"
    build_text = build_text ++ "pub fn build(ctx: BuildCtx) -> Build:\n"
    build_text = build_text ++ "    var out = ctx.new_build()\n"
    build_text = build_text ++ "    out = out.install(\"put\", \"src/payload.txt\", \"$HOME/.local/with-behav-1884/payload.txt\")\n"
    build_text = build_text ++ "    out.default(\"put\")\n"
    p7_write(case_dir, "build.w", build_text)
    p7_write(case_dir, "src/payload.txt", "payload\n")
    let dest_dir = profile ++ "\\.local\\with-behav-1884"
    let _clean = remove_tree(dest_dir)
    let ran = p7_run(case_dir, "1884-home-unset", p7_build_args())
    p7_assert_success(ran, "install under $HOME with HOME unset")
    assert(read_file(dest_dir ++ "\\payload.txt").unwrap() == "payload\n")
    assert(remove_tree(dest_dir) == 0)
    print("ok")
