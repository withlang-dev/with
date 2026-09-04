// tools/debug_drop.w — native harness driver for the debug allocator.
//
// Runs a repro (or a corpus of fixtures) under the native debug allocator
// (WITH_DEBUG_ALLOC) and reports the verdict. See docs/debug-allocator.md.
//
//   ./out/release/bin/with build tools/debug_drop.w -o out/debug-alloc-tests/debug_drop
//   out/debug-alloc-tests/debug_drop run   <with-bin> <repro.w>
//   out/debug-alloc-tests/debug_drop check <with-bin> <fixture.w> [more...]
//
// `run`   prints the debug-alloc verdict lines (DOUBLE FREE / LEAK / count).
// `check` runs each fixture under the debug allocator and asserts the captured
//         output contains the fixture's `//! expect-debug-alloc: <substr>`
//         directive. Exits non-zero if any fixture fails (the commit-gate lane).
//
// Source SITES for a flagged address are resolved separately with lldb; see
// tools/debug_drop_sites.lldb and tools/debug_drop_fields.lldb.

use std.process

extern fn with_exec_argv_capture(argv: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32
extern fn with_fs_read_file(path: &str) -> str

fn exec_capture(argv: &str, outp: &str, errp: &str, timeout: i32) -> i32:
    unsafe:
        with_exec_argv_capture(argv, outp, errp, timeout)

fn read_file(path: &str) -> str:
    unsafe:
        with_fs_read_file(path)

// NUL-joined argv (the tool_process_argv encoding the exec runtime expects).
fn argv4(a: &str, b: &str, c: &str, d: &str) -> str:
    a ++ "\0" ++ b ++ "\0" ++ c ++ "\0" ++ d ++ "\0"

fn argv5(a: &str, b: &str, c: &str, d: &str, e: &str) -> str:
    a ++ "\0" ++ b ++ "\0" ++ c ++ "\0" ++ d ++ "\0" ++ e ++ "\0"

// Run `<with-bin> run --debug-alloc <repro>`; return (exit code, captured
// stderr+stdout text). The exit code is part of the verdict: a fixture that
// expects a clean report must also exit 0, so an inline `assert(drops == N)`
// abort or a SIGSEGV fails the lane even when the report line still matches
// (#697: fixtures crashed AFTER printing the expected line and passed).
fn run_under_debug_alloc(with_bin: &str, repro: &str, filter: &str) -> (i32, str):
    let outp = "/tmp/debug_drop_out.txt"
    let errp = "/tmp/debug_drop_err.txt"
    let argv = if filter.len() > 0:
        argv5(with_bin, "run", "--debug-alloc", "--debug-alloc-filter=" ++ filter, repro)
    else:
        argv4(with_bin, "run", "--debug-alloc", repro)
    let rc = exec_capture(argv, outp, errp, 60000)
    (rc, read_file(errp) ++ "\n" ++ read_file(outp))

// Index of `sub` in `s`, or -1.
fn find_sub(s: &str, sub: &str) -> i64:
    let n = s.len()
    let m = sub.len()
    if m == 0:
        return 0
    var i: i64 = 0
    while i + m <= n:
        var j: i64 = 0
        var ok = true
        while j < m:
            if s[i + j] != sub[j]:
                ok = false
                break
            j = j + 1
        if ok:
            return i
        i = i + 1
    -1

// Text from just after `prefix` to end of that line, leading spaces trimmed.
fn line_after_prefix(src: &str, prefix: &str) -> str:
    let idx = find_sub(src, prefix)
    if idx < 0:
        return ""
    var start = idx + prefix.len()
    let n = src.len()
    while start < n and src[start] == 32:        // skip spaces
        start = start + 1
    var end = start
    while end < n and src[end] != 10:            // to newline
        end = end + 1
    src.slice(start, end)

fn main:
    let a = args()
    if a.len() < 4:
        print("usage: debug_drop <run|check> <with-bin> <target.w> [more fixtures...]")
        exit_code(2)
    let mode = a.get(1)
    let with_bin = a.get(2)

    if mode == "run":
        let repro = a.get(3)
        let filter = line_after_prefix(read_file(repro), "debug-alloc-filter:")
        let (rc, report) = run_under_debug_alloc(with_bin, repro, filter)
        print("=== debug-alloc: " ++ repro ++ " (exit " ++ f"{rc}" ++ ") ===")
        if report.contains("DOUBLE FREE"):
            print(line_after_prefix(report, "debug-alloc: DOUBLE FREE"))
            print("verdict: DOUBLE FREE (resolve sites with tools/debug_drop_sites.lldb)")
        else if report.contains("LEAK addr="):
            print(line_after_prefix(report, "debug-alloc: leak count="))
            print("verdict: LEAK (resolve alloc site with tools/debug_drop_sites.lldb)")
        else:
            print("verdict: clean (no double-free, no leak)")
        exit_code(0)

    // Fixture conventions (#697, learned the hard way):
    //   - a consuming callee must actually consume (`let sink = x`); an unused
    //     by-value param infers no effects, becomes share-place, and the call
    //     tests no move at all
    //   - structs whose field is moved need a NON-ZERO sibling field, or the
    //     blank makes the whole value the reset sentinel and the whole-value
    //     guard masks a missing member-level guard
    //   - clean fixtures must exit 0 (enforced below); a fixture expecting a
    //     failure report (DOUBLE FREE / first_drop=) may abort
    if mode == "check":
        var failed: i64 = 0
        var i: i64 = 3
        while i < a.len():
            let fx = a.get(i)
            let want = line_after_prefix(read_file(fx), "expect-debug-alloc:")
            let filter = line_after_prefix(read_file(fx), "debug-alloc-filter:")
            let (rc, report) = run_under_debug_alloc(with_bin, fx, filter)
            let expects_abort = want.contains("DOUBLE FREE") or want.contains("first_drop=")
            if want.len() > 0 and report.contains(want) and (expects_abort or rc == 0):
                print("PASS " ++ fx)
            else:
                print("FAIL " ++ fx ++ "  (want: '" ++ want ++ "', exit " ++ f"{rc}" ++ ")")
                failed = failed + 1
            i = i + 1
        if failed > 0:
            print("debug-alloc lane: FAILED")
            exit_code(1)
        print("debug-alloc lane: ok")
        exit_code(0)

    print("unknown mode: " ++ mode)
    exit_code(2)
