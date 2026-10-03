// tools/debug_drop.w — native harness driver for the debug allocator.
//
// Runs a repro (or a corpus of fixtures) under the native debug allocator
// (WITH_DEBUG_ALLOC) and reports the verdict. See docs/spec/toolchain/debug-allocator.md.
//
//   ./out/release/bin/with build tools/debug_drop.w -o out/debug-alloc-tests/debug_drop
//   out/debug-alloc-tests/debug_drop run   <with-bin> <repro.w>
//   out/debug-alloc-tests/debug_drop check <with-bin> <fixture.w> [more...]
//
// `run`   prints the debug-alloc verdict lines (DOUBLE FREE / LEAK / count).
// `check` runs each fixture under the debug allocator and asserts the captured
//         output contains the fixture's `//! expect-debug-alloc: <substr>`
//         directive, and that the program's stdout is exactly its
//         `//! expect-stdout:` lines: every line, in order, once each — the
//         test runner's rule (#1855), here over the run the fixture pins,
//         the one under the debug allocator (#1865). Exits non-zero if any
//         fixture fails (the commit-gate lane).
//
// Source SITES for a flagged address are resolved separately with lldb; see
// tools/debug_drop_sites.lldb and tools/debug_drop_fields.lldb.

use std.fs
use std.process
use std.time.now_ns

// One run under the debug allocator: the exit code is part of the verdict
// (a fixture that expects a clean report must also exit 0, so an inline
// `assert(drops == N)` abort or a SIGSEGV fails the lane even when the
// report line still matches — #697: fixtures crashed AFTER printing the
// expected line and passed). `report` is stderr then stdout.
type DebugAllocRun { rc: i32, report: str, stdout: str }

fn run_under_debug_alloc(with_bin: &str, repro: &str, filter: &str) -> DebugAllocRun:
    // Per process: concurrent lanes (two batteries, an agent's run) shared
    // one capture file and read each other's half-written report (#2004).
    let outp = f"/tmp/debug_drop_{pid()}_out.txt"
    let errp = f"/tmp/debug_drop_{pid()}_err.txt"
    var argv: Vec[str] = Vec.new()
    argv.push(with_bin.clone())
    argv.push("run")
    argv.push("--debug-alloc")
    if filter.len() > 0: argv.push("--debug-alloc-filter=" ++ filter)
    argv.push(repro.clone())
    let finished = run_to_files(&argv, outp, errp, 60000)
    let stdout = read_file(outp) ?? ""
    DebugAllocRun { rc: finished.code, report: (read_file(errp) ?? "") ++ "\n" ++ stdout, stdout }

// Text from just after `prefix` to end of that line, leading spaces trimmed.
fn line_after_prefix(src: &str, prefix: &str) -> str:
    let idx = src.find(prefix)
    if idx < 0: return ""
    var start = idx + prefix.len()
    while start < src.len() and src[start] == ' ': start = start + 1
    var end = start
    while end < src.len() and src[end] != '\n': end = end + 1
    src.slice(start, end)

// Every `//! expect-stdout:` value, in order.
fn expected_stdout_lines(source: &str) -> Vec[str]:
    var lines: Vec[str] = Vec.new()
    for line in source.split("\n"):
        if line.starts_with("//! expect-stdout:"):
            var value = line.slice("//! expect-stdout:".len(), line.len())
            if value.starts_with(" "): value = value.slice(1, value.len())
            lines.push(value)
    lines

// "" when stdout is exactly the expected lines; otherwise what differs first.
fn stdout_mismatch(expected: &Vec[str], stdout: &str) -> str:
    var actual: Vec[str] = Vec.new()
    for line in stdout.split("\n"): actual.push(line.clone())
    // print ends every line: the text after the last newline is empty.
    if actual.len() > 0 and actual[actual.len() as i32 - 1].len() == 0: let _ = actual.pop()
    let n = if expected.len() < actual.len(): expected.len() else: actual.len()
    for k in 0..n as i32:
        if expected[k] != actual[k]:
            return f"stdout line {k + 1}: expected '" ++ expected[k] ++ "', got '" ++ actual[k] ++ "'"
    if actual.len() < expected.len():
        return f"stdout has {actual.len()} line(s), expected {expected.len()}; first missing: '" ++ expected[actual.len() as i32] ++ "'"
    if actual.len() > expected.len():
        return f"stdout has {actual.len()} line(s), expected {expected.len()}; first unlisted: '" ++ actual[expected.len() as i32] ++ "'"
    ""

fn main:
    let a = args()
    if a.len() < 4:
        print("usage: debug_drop <run|check> <with-bin> <target.w> [more fixtures...]")
        exit_code(2)
    let mode = a[1]
    let with_bin = a[2]

    if mode == "run":
        let repro = a[3]
        // Bound, not passed inline: #1974.
        let source = read_file(repro) ?? ""
        let filter = line_after_prefix(source, "debug-alloc-filter:")
        let run = run_under_debug_alloc(with_bin, repro, filter)
        print("=== debug-alloc: " ++ repro ++ f" (exit {run.rc}) ===")
        if run.report.contains("DOUBLE FREE"):
            print(line_after_prefix(run.report, "debug-alloc: DOUBLE FREE"))
            print("verdict: DOUBLE FREE (resolve sites with tools/debug_drop_sites.lldb)")
        else if run.report.contains("LEAK addr="):
            print(line_after_prefix(run.report, "debug-alloc: leak count="))
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
        var failed = 0
        for i in 3..a.len() as i32:
            let fx = a[i]
            let source = read_file(fx) ?? ""
            let want = line_after_prefix(source, "expect-debug-alloc:")
            let filter = line_after_prefix(source, "debug-alloc-filter:")
            print("START " ++ fx)
            let started = now_ns()
            let run = run_under_debug_alloc(with_bin, fx, filter)
            let elapsed_ms = (now_ns() - started) / 1000000
            let expects_abort = want.contains("DOUBLE FREE") or want.contains("first_drop=")
            let expected = expected_stdout_lines(source)
            let stdout_diff = if expected.len() > 0: stdout_mismatch(&expected, run.stdout) else: ""
            if want.len() > 0 and run.report.contains(want) and (expects_abort or run.rc == 0) and stdout_diff.len() == 0:
                print("PASS " ++ fx ++ f" ({elapsed_ms} ms)")
            else:
                var why = "want: '" ++ want ++ f"', exit {run.rc}"
                if stdout_diff.len() > 0: why = why ++ "; " ++ stdout_diff
                print("FAIL " ++ fx ++ "  (" ++ why ++ f", {elapsed_ms} ms)")
                failed = failed + 1
        if failed > 0:
            print("debug-alloc lane: FAILED")
            exit_code(1)
        print("debug-alloc lane: ok")
        exit_code(0)

    print("unknown mode: " ++ mode)
    exit_code(2)
