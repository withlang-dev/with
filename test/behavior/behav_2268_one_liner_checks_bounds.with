//! expect-stdout: ok
// #2268 (§4.3a, D71): an index past the end panics in every build but
// `--release`. The checks were emitted only with debug info, so a one-liner
// (built without it) read past the end and exited 0.
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
    let base = temp_root() ++ f"/with-behav-2268-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base) == 0)
    let ran = run_to_files(&[compiler, "-e", "let a = [1, 2]", "-e", "print(f\"{a[5]}\")"], base ++ "/stdout", base ++ "/stderr", 120000)
    let err = read_file(base ++ "/stderr") ?? ""
    if ran.code == 0 or not err.contains("index out of bounds"):
        print(f"code {ran.code} stderr {err}")
        exit_code(1)
    let _done = remove_tree(base)
    print("ok")
