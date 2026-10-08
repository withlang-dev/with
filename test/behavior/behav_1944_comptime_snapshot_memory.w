//! expect-stdout: ok

use std.fs
use std.process

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let dir = f"out/tmp/comptime-snapshot-{pid()}"
    assert(mkdir_p(dir) == 0)
    let stdout_path = dir ++ "/stdout"
    let stderr_path = dir ++ "/stderr"
    let saved_limit = env("WITH_MEMORY_LIMIT_BYTES")
    // Repeated reads of the 64 KiB receiver exceeded this limit before
    // branch-local cleanup was restored (#1944).
    // This bounds the actual allocation path, independent of host RSS noise.
    assert(set_env("WITH_MEMORY_LIMIT_BYTES", "33554432") == 0)
    let checked = run_to_files(&[compiler, "check", "test/behavior/lib/comptime_reader_snapshots.w"], stdout_path, stderr_path, 30000)
    assert(set_env("WITH_MEMORY_LIMIT_BYTES", saved_limit) == 0)
    if checked.code != 0:
        print(read_file(stderr_path).unwrap())
    assert(not checked.timed_out)
    assert(checked.code == 0)
    // Exercise the materialized value as well as the evaluator's memory use.
    let ran = run_to_files(&[compiler, "run", "test/behavior/lib/comptime_reader_snapshots.w"], stdout_path, stderr_path, 30000)
    assert(not ran.timed_out)
    assert(ran.code == 0)
    assert(read_file(stdout_path).unwrap() == "ok\n")
    assert(remove_tree(dir) == 0)
    print("ok")
