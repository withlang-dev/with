// tools/debug_drop.w — native harness driver for the debug allocator.
//
// Runs a repro (or a corpus of fixtures) under the native debug allocator
// (WITH_DEBUG_ALLOC) and reports the verdict. See debug-allocator.md.
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
use std.os
use std.process
use std.time.now_ns

// One run under the debug allocator: the exit code is part of the verdict
// (a fixture that expects a clean report must also exit 0, so an inline
// `assert(drops == N)` abort or a SIGSEGV fails the lane even when the
// report line still matches — #697: fixtures crashed AFTER printing the
// expected line and passed). `report` is stderr then stdout.
type DebugAllocRun { rc: i32, report: str, stdout: str }

// The fixture's file name, the part of its path after the last separator.
fn capture_stem(repro: &str) -> str:
    var start = 0
    for i in 0..repro.len():
        if repro[i] == '/' or repro[i] == '\\': start = i + 1
    repro.slice(start, repro.len())

fn run_under_debug_alloc(with_bin: &str, repro: &str, filter: &str) -> DebugAllocRun:
    // Per process and per test: concurrent lanes (two batteries, an agent's
    // run) shared one capture file and read each other's half-written report
    // (#2004); one path for every test of a lane let a program a timed-out
    // test left running write its report line into the next test's capture
    // through the handle it inherited (#2902, windows-aarch64).
    let outp = f"/tmp/debug_drop_{pid()}_{capture_stem(repro)}_out.txt"
    let errp = f"/tmp/debug_drop_{pid()}_{capture_stem(repro)}_err.txt"
    var argv: List[str] = List.new()
    argv.push(with_bin.clone())
    argv.push("run")
    argv.push("--debug-alloc")
    if filter.len() > 0: argv.push("--debug-alloc-filter=" ++ filter)
    argv.push(repro.clone())
    // The hang guard a test binary gets (#2362, TEST_HANG_GUARD_MS), not a
    // speed budget: at 60 s a passing fixture failed on a loaded 4-core
    // runner with nothing captured (#2902).
    let finished = run_to_files(&argv, outp, errp, 1800000)
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
fn expected_stdout_lines(source: &str) -> List[str]:
    var lines: List[str] = List.new()
    for line in source.split("\n"):
        if line.starts_with("//! expect-stdout:"):
            var value = line.slice("//! expect-stdout:".len(), line.len())
            if value.starts_with(" "): value = value.slice(1, value.len())
            lines.push(value)
    lines

// "" when stdout is exactly the expected lines; otherwise what differs first.
fn stdout_mismatch(expected: &List[str], stdout: &str) -> str:
    var actual: List[str] = List.new()
    for line in stdout.split("\n"): actual.push(line.clone())
    // print ends every line: the text after the last newline is empty.
    if actual.len() > 0 and actual[actual.len() - 1].len() == 0: let _ = actual.pop()
    let n = if expected.len() < actual.len(): expected.len() else: actual.len()
    for k in 0..n as i32:
        if expected[k] != actual[k]:
            return f"stdout line {k + 1}: expected '" ++ expected[k] ++ "', got '" ++ actual[k] ++ "'"
    if actual.len() < expected.len():
        return f"stdout has {actual.len()} line(s), expected {expected.len()}; first missing: '" ++ expected[actual.len()] ++ "'"
    if actual.len() > expected.len():
        return f"stdout has {actual.len()} line(s), expected {expected.len()}; first unlisted: '" ++ actual[expected.len()] ++ "'"
    ""

// #807: the platform gates `with test` reads (`//! skip-on: <value>
// <reason>`, `//! only-on: <value>`), so a fixture that needs a host's
// program or headers says so instead of failing every other host. A value
// is an OS (windows, linux, darwin), an ISA (aarch64, x86_64) or an os-arch
// pair; an unknown one fails the fixture, never runs it everywhere.
fn gate_os_matches(value: &str) -> bool:
    let host = os()
    if value == "windows": return host == "Windows"
    if value == "linux": return host == "Linux"
    if value == "darwin": return host == "Macos"
    false

fn gate_is_os(value: &str) -> bool: value == "windows" or value == "linux" or value == "darwin"

fn gate_is_arch(value: &str) -> bool: value == "aarch64" or value == "x86_64"

fn gate_arch_matches(value: &str) -> bool:
    let host = arch()
    if value == "aarch64": return host == "aarch64" or host == "arm64"
    host == "x86_64" or host == "amd64"

// 1 the host matches, 0 it does not, -1 the value is unknown.
fn gate_matches(value: &str) -> i32:
    if gate_is_os(value): return if gate_os_matches(value): 1 else: 0
    if gate_is_arch(value): return if gate_arch_matches(value): 1 else: 0
    let dash = value.find("-")
    if dash > 0:
        let os_part = value.slice(0, dash)
        let arch_part = value.slice(dash + 1, value.len())
        if gate_is_os(os_part) and gate_is_arch(arch_part):
            return if gate_os_matches(os_part) and gate_arch_matches(arch_part): 1 else: 0
    -1

// "" to run the fixture here, "skip" to skip it, or why the gate is bad.
fn fixture_gate(source: &str) -> str:
    for line in source.split("\n"):
        if line.starts_with("//! skip-on: "):
            let value = line.slice(13, line.len()).split(" ")[0].to_owned()
            let m = gate_matches(value)
            if m < 0: return f"skip-on: unknown platform value '{value}'"
            if m == 1: return "skip"
        if line.starts_with("//! only-on: "):
            let value = line.slice(13, line.len()).trim().to_owned()
            let m = gate_matches(value)
            if m < 0: return f"only-on: unknown platform value '{value}'"
            if m == 0: return "skip"
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
        else if not run.report.contains("debug-alloc: leak count="):
            // The exit report is unconditional; without it the allocator
            // never reported (the program died first, or did not run).
            print("verdict: NO REPORT (the debug allocator printed no exit report; the run did not reach a normal exit)")
        else:
            print(line_after_prefix(run.report, "debug-alloc: leak count="))
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
        for i in 3..a.len():
            let fx = a[i]
            let source = read_file(fx) ?? ""
            let gate = fixture_gate(source)
            if gate == "skip":
                print("SKIP " ++ fx)
                continue
            if gate.len() > 0:
                print("FAIL " ++ fx ++ "  (" ++ gate ++ ")")
                failed = failed + 1
                continue
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
