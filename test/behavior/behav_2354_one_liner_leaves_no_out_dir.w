//! expect-stdout: ok
// #2354: a one-liner leaves nothing in the directory it runs in. `with -e`
// created out/tmp/with_runtime (and its binary under out/tmp) in any cwd,
// inside a project or not; it now builds under the user's cache.
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
    let base = temp_root() ++ f"/with-behav-2354-{pid()}"
    let _clean = remove_tree(base)
    let work = base ++ "/work"
    assert(mkdir_p(work) == 0)
    let ran = run_to_files_in(work, &[compiler, "-e", "print(2354)"], base ++ "/stdout", base ++ "/stderr")
    let out = read_file(base ++ "/stdout") ?? ""
    if ran.code != 0 or out != "2354\n" or file_exists(work ++ "/out"):
        print(f"code {ran.code} stdout {out} stderr {read_file(base ++ "/stderr") ?? ""}")
        print(f"out/ left in the working directory: {file_exists(work ++ "/out")}")
        exit_code(1)
    let _done = remove_tree(base)
    print("ok")
