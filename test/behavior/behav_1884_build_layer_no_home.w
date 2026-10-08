//! expect-stdout: ok

// #1884: with no home directory (HOME unset, and on Windows USERPROFILE
// too), this repository's own build graph stops at evaluation with a
// diagnostic that names the variables. It planned the wo store at
// `/.local/with-wo/...` instead, and the build failed late, after stage1
// and stage2, as an install that "escapes project root". (A Windows shell
// without HOME but with USERPROFILE resolves the home from it: build/
// compiler.w comp_home_dir, behav_1884_windows_install_home_unset.w.)
//
// `build --graph` evaluates build.w and prints the plan; it takes no build
// lock, and a failed evaluation writes no build state.
use pre_d_build_runner
use std.fs
use std.process
use std.sysinfo

fn main:
    let saved_home = env("HOME")
    let saved_profile = env("USERPROFILE")
    assert(set_env("HOME", "") == 0)
    if os() == "Windows":
        assert(set_env("USERPROFILE", "") == 0)
    let ran = p7_run(p7_repo_root(), "1884-no-home", p7_build_graph_args())
    assert(set_env("HOME", saved_home) == 0)
    assert(set_env("USERPROFILE", saved_profile) == 0)
    p7_assert_failure_contains(ran, "have no home directory", "repo graph with no home")
    assert(not ran.stdout.contains("/.local/with-wo"))
    print("ok")
