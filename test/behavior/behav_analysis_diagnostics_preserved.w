//! expect-stdout: ok

use std.fs
use std.process

// Failed compilation still has diagnostic facts. The frontend transfers
// their ownership to Zcu; querying the emptied Sema list hid every row.
fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let dir = f"out/tmp/analysis-diagnostics-{pid()}"
    assert(mkdir_p(dir) == 0)
    for reverse in [false, true]:
        var argv: Vec[str] = Vec.new()
        argv.push(compiler)
        argv.push("analyze")
        argv.push("test/compile_errors/err_d21_mut_receiver_owned_escape.w")
        argv.push("select:kind=diagnostic")
        if reverse: argv.push("--sema-body-order-reverse")
        let result = run_to_files(argv, dir ++ "/stdout", dir ++ "/stderr", 30000)
        assert(not result.timed_out)
        assert(result.code != 0)
        let report = read_file(dir ++ "/stdout").unwrap()
        assert(report.contains("fact\tdiagnostic\tdiagnostic\t"))
        assert(report.contains("mut receiver is too weak"))
        assert(report.contains("enforce_receiver_modes"))
        assert(report.contains("origin-node-file=0"))
        assert(report.contains("compilation failed"))
    assert(remove_tree(dir) == 0)
    print("ok")
