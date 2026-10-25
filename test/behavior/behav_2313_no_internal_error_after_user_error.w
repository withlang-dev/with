//! expect-stdout: ok
// #2313: an internal error must never follow a user error. After the
// array-length error below, a re-check lost the first join decision's
// demand and reported "internal error: conflicting contextual join
// decisions for one expression".
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
    let base = temp_root() ++ f"/with-behav-2313-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base) == 0)
    let src = base ++ "/len.w"
    assert(write_file(src, "fn main:\n    let b: [4]i32 = [1, 2]\n    print(f\"{b[3]}\")\n") == 0)
    let ran = run_to_files(&[compiler, "check", src], base ++ "/stdout", base ++ "/stderr", 120000)
    let err = read_file(base ++ "/stderr") ?? ""
    if ran.code == 0 or not err.contains("array literal has 2 elements") or err.contains("internal error"):
        print(f"code {ran.code} stderr {err}")
        exit_code(1)
    let _done = remove_tree(base)
    print("ok")
