//! expect-stdout: ok
// #1146: `with install-user` outside a project installs the running compiler
// to ~/.local/bin, as the help says. It went straight to the build graph and
// said "'build' requires a source file argument, build.w, or a with.toml
// project".
use std.fs
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    let temp = env("TEMP")
    if temp.len() > 0: return temp
    "/tmp"

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-1146-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base ++ "/empty") == 0 and mkdir_p(base ++ "/home") == 0)
    assert(set_env("HOME", base ++ "/home") == 0)
    let ran = run_to_files_in(base ++ "/empty", &[compiler, "install-user"], base ++ "/stdout", base ++ "/stderr")
    let out = read_file(base ++ "/stdout") ?? ""
    let err = read_file(base ++ "/stderr") ?? ""
    if ran.code != 0 or not file_exists(base ++ "/home/.local/bin/with"):
        print(f"code {ran.code} stdout {out} stderr {err}")
        exit_code(1)
    let _done = remove_tree(base)
    print("ok")
