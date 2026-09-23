//! expect-stdout: ok

// #1387: the string-splitting C expression parser hands the whole text to the
// next precedence level whenever a split fails, so on text that is not an
// expression its work multiplies across the split points: this macro body took
// 3.9 s at 100 fragments, 104 s at 200, and did not finish at 400. Every level
// now spends from one scan budget per expression; past it the macro is left
// untranslated with a warning that names the size, in bounded time.
//
// #1465: the warning is part of the translation. The persistent c_import
// cache (~/.cache/with/c_import) stores it with the entry and a hit prints it
// again, so the second compile of the same header warns exactly as the first
// (it was silent, and this fixture failed on every run after the first with
// one compiler). A fresh cache epoch makes the first run a miss.

use pre_d_build_runner
use std.process
use std.string.StringBuilder
use std.time

fn check_warned(run: &P7Run, label: &str):
    p7_assert_success(run, label)
    assert(run.stdout.contains("small"))
    assert(run.stderr.contains("exceeded the translator's scan budget"))

fn main:
    let case_dir = p7_prepare_case("c_import_expr_scan_budget", "exprscanbudget")
    var h = StringBuilder.new()
    h.push_str("#define BIG ")
    for i in 0..400:
        h.push_str(f"M{i}(a) ((a) * {i} + 1) - ((a) << 2) * 3 / 4 >= ")
    h.push_str("0\n#define SMALL (3 * (1 + 2) - 1)\n")
    p7_write(case_dir, "src/big.h", h.to_str())
    p7_write(case_dir, "src/main.w", "use c_import(\"big.h\")\nfn main:\n    assert(SMALL == 8)\n    print(\"small\")\n")
    let previous_epoch = env("WITH_CIMPORT_CACHE_EPOCH").clone()
    let previous_trace = env("WITH_TRACE_CIMPORT_CACHE").clone()
    assert(set_env("WITH_CIMPORT_CACHE_EPOCH", f"scan-budget-{pid()}-{now_ns()}") == 0)
    assert(set_env("WITH_TRACE_CIMPORT_CACHE", "1") == 0)
    let miss = p7_run(case_dir, "c_import expr scan budget (cache miss)", "run\0src/main.w\0")
    let hit = p7_run(case_dir, "c_import expr scan budget (cache hit)", "run\0src/main.w\0")
    assert(set_env("WITH_CIMPORT_CACHE_EPOCH", previous_epoch) == 0)
    assert(set_env("WITH_TRACE_CIMPORT_CACHE", previous_trace) == 0)
    check_warned(&miss, "cache miss")
    check_warned(&hit, "cache hit")
    assert(miss.stderr.contains("c_import cache miss"))
    assert(hit.stderr.contains("c_import cache hit (fs)"))
    print("ok")
