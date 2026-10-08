//! expect-stdout: ok

use pre_d_build_runner
use std.process
use std.fs

fn main:
    let root = p7_repo_root()
    let override_tool = env("WITH_ORDER_CHECK_TOOL")
    let dir = p7_prepare_case(if override_tool.len() > 0: "sema_order_checker_verdicts_before" else: "sema_order_checker_verdicts_after", "orderverdicts")
    let tool = if override_tool.len() > 0: override_tool else: p7_join(root, "tools/sema_order_check.w")
    p7_write(dir, "probe.w", "use std.process\nfn main:\n    let mode = env(\"WITH_ORDER_PROBE_MODE\")\n    var reverse_order = false\n    for arg in args():\n        if arg == \"--sema-body-order-reverse\": reverse_order = true\n    if mode == \"status\" and reverse_order: exit_code(0)\n    if mode == \"invalid\": exit_code(70)\n    if mode == \"streams\":\n        if reverse_order:\n            print(\"a\\nb\")\n            eprint(\"c\")\n        else:\n            print(\"a\")\n            eprint(\"b\\nc\")\n    exit_code(1)\n")
    let built = p7_run(dir, "order_verdict_probe_build", "build\0probe.w\0-o\0probe\0")
    assert(built.rc == 0)
    p7_write(dir, "fixtures/case.w", "fn main: print(0)\n")
    p7_write(dir, "allowlist.txt", "")
    // The previous tool has fixed paths; its positive control sees the same
    // one-fixture corpus before the status probe demonstrates its false green.
    p7_write(dir, "test/compile_errors/case.w", "fn main: print(0)\n")
    p7_write(dir, "test/sema_order_allowlist.txt", "")
    p7_write(dir, "empty/keep.txt", "no With fixtures\n")
    let previous_mode = env("WITH_ORDER_PROBE_MODE")
    for mode in ["equal", "status", "invalid", "streams", "missing", "empty"]:
        assert(set_env("WITH_ORDER_PROBE_MODE", mode) == 0)
        let probe = p7_join(dir, if mode == "missing": "no-such-compiler" else: "probe")
        let fixtures = p7_join(dir, if mode == "empty": "empty" else: "fixtures")
        let output = p7_join(dir, "verdict-" ++ mode)
        let result = p7_run(dir, "order_verdict_" ++ mode, "run\0" ++ tool ++ "\0" ++ probe ++ "\0" ++ output ++ "\0" ++ fixtures ++ "\0" ++ p7_join(dir, "allowlist.txt") ++ "\0")
        if mode == "equal":
            assert(result.rc == 0)
            assert(result.stdout.contains("0 of 1 fixtures differ"))
        else:
            assert(result.rc != 0)
        if mode == "status":
            let report = read_file(p7_join(output, "report.txt")).unwrap()
            assert(report.contains("exit forward=1 reverse=0"))
        if mode == "invalid" or mode == "missing":
            assert(result.stdout.contains("1 runner failures"))
        if mode == "streams":
            assert(result.stdout.contains("1 of 1 fixtures differ"))
        if mode == "empty":
            assert(result.stdout.contains("no fixtures found"))
    assert(set_env("WITH_ORDER_PROBE_MODE", previous_mode) == 0)
    print("ok")
