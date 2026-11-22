//! expect-stdout: refused true
//! expect-stderr: could not open a command's
// #2725: a capture file the spawn cannot open is said, with its path, and
// the run fails. A directory as the stdout path made the child exit 127
// with nothing on stderr on POSIX (indistinguishable from the command's own
// 127), and on Windows the child ran with its output silently lost.
use std.fs
use std.process

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let tmp = env("TMPDIR")
    let base = (if tmp.len() > 0: tmp else: "/tmp") ++ f"/with-behav-2725-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base ++ "/out") == 0)
    let ran = run_to_files(&[compiler, "--version"], base ++ "/out", base ++ "/err", 20000)
    print(f"refused {ran.code != 0}")
    let _done = remove_tree(base)
