//! skip-on: windows issue #802: core-language behavior fails on native Windows (needs root-cause)
//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.string.StringBuilder
use std.time

extern fn with_exec_argv_capture(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32) -> i32

// #1358: `with ast lib/std/tommyds/check_.w` (72 KB) ran for more than 36
// minutes. The file declares `var the_cache: [16777216]u8 = [0 as u8;
// 16777216]`; the parser desugars a fill into N copies of one element node,
// and the dump printed every copy (150 MB), each appended by copying the
// whole list so far: the renderer grew its lists with `out = out ++ piece`
// after an `if`, a form that copies `out` on every append (#1491). The dump
// now prints a fill as written and builds every list in one buffer.
fn dump(dir: &str, name: &str) -> str:
    let rc = unsafe { with_exec_argv_capture(f"{p7_compiler_path()}\0ast\0{p7_join(dir, name)}\0", p7_join(dir, name ++ ".out"), p7_join(dir, name ++ ".err"), 120000) }
    assert(rc == 0)
    read_file(p7_join(dir, name ++ ".out")).unwrap()

fn elapsed_ns(dir: &str, name: &str) -> i64:
    let start = now_ns()
    let _ = dump(dir, name)
    now_ns() - start

fn median_ns(dir: &str, name: &str) -> i64:
    let a = elapsed_ns(dir, name)
    let b = elapsed_ns(dir, name)
    let c = elapsed_ns(dir, name)
    if a < b:
        if b < c: b else if a < c: c else: a
    else:
        if a < c: a else if b < c: c else: b

fn list_literal(n: i32) -> str:
    var text = StringBuilder.new()
    text.push_str("let TABLE: [")
    text.push_str(f"{n}")
    text.push_str("]i32 = [")
    for i in 0..n:
        if i > 0: text.push_str(", ")
        text.push_str(f"{i}")
    text.push_str("]\n")
    text.to_str()

fn main:
    let dir = p7_prepare_case("ast_dump_linear", "astdumplinear")

    p7_write(dir, "fill.w", "var the_cache: [16777216]u8 = [0 as u8; 16777216]\n")
    let fill = dump(dir, "fill.w")
    assert(fill.contains("; 16777216]"))
    assert(fill.len() < 200)

    // A written list: the dump's time grows linearly with its length
    // (the bound of test/complexity: large <= max(small, 1 ms) * 6 + 1 ms,
    // here with 200 ms of process-start slack).
    p7_write(dir, "small.w", list_literal(40000))
    p7_write(dir, "large.w", list_literal(160000))
    assert(dump(dir, "large.w").contains(", 159999]"))
    let small = median_ns(dir, "small.w")
    let large = median_ns(dir, "large.w")
    let base = if small > 1000000: small else: 1000000
    if large > base * 6 + 200000000:
        eprint(f"ast of a 160000-element literal took {large} ns, 40000 took {small} ns")
        assert(false)
    print("ok")
