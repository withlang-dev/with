//! expect-stdout: ok

use std.fs
use std.os
use std.process

// A child past its timeout is stopped and reported as timed out, with
// nothing else run: the runtime once ran the host's /usr/bin/sample on it
// first and printed `timeout: child N sampled to …` on the waiting
// program's stderr (the toolchain runs no host command, 2026-10-28). The
// probe is that waiting program, so its stderr is what is read here. `-o`
// names the file exactly, and Windows runs an extensionless name as its
// `.exe`, so both programs are built under that name there.
fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let dir = f"out/tmp/process-timeout-{pid()}"
    let exe = if os() == "Windows": ".exe" else: ""
    assert(mkdir_p(dir) == 0)
    assert(write_file(dir ++ "/sleep.w", "use std.time\nsleep_secs(30)\n") == 0)
    let probe = "use std.process\nlet r = run_to_files(&[\"" ++ dir ++ "/sleep" ++ exe ++ "\"], \"" ++ dir ++ "/sleep.out\", \"" ++ dir ++ "/sleep.err\", 500)\nprint(if r.timed_out: \"timed out\" else: \"ran\")\n"
    assert(write_file(dir ++ "/probe.w", probe) == 0)
    for name in ["sleep", "probe"]:
        let built = run_to_files(&[compiler, "build", dir ++ "/" ++ name ++ ".w", "-o", dir ++ "/" ++ name ++ exe], dir ++ "/build.out", dir ++ "/build.err", 120000)
        assert(built.code == 0)
    let result = run_to_files(&[dir ++ "/probe" ++ exe], dir ++ "/probe.out", dir ++ "/probe.err", 60000)
    assert(result.code == 0)
    assert((read_file(dir ++ "/probe.out") ?? "").trim() == "timed out")
    let err = read_file(dir ++ "/probe.err") ?? ""
    if err.len() > 0: print(err)
    assert(remove_tree(dir) == 0)
    print("ok")
