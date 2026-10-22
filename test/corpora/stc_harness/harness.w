module std.stc_testing.harness

// The With half of STC's test harness. Upstream's tests are ctest.h
// programs: the TEST bodies are plain C and migrate (test/corpora/stc), but
// the runner under CTEST_MAIN registers tests through a linker section and
// skips a failed assertion with longjmp, neither of which has a With
// spelling. The migrated units call ctest.h's assertion functions as
// externs; these are those functions, exported under their C names for
// that reason alone (the units are migrated With, not foreign code), and a
// failed assertion is recorded and reported instead of jumped over.

use rt.rt_core
use std.collections

// Exported functions may be entered from any thread, so the count is atomic.
var ctest_failures: Atomic[i64] = Atomic.new(0)

pub fn ctest_failure_count() -> c_int: ctest_failures.load(.SeqCst) as c_int

pub unsafe fn ctest_text(p: *const i8) -> str:
    if p == null: return "(null)"
    with_str_from_cstr(p as *const u8)

fn ctest_fail(caller: *const i8, line: c_int, what: str):
    ctest_failures.fetch_add(1, .SeqCst)
    eprint(f"FAIL {unsafe { ctest_text(caller) }}:{line}: {what}")

fn ctest_cmp_holds(cmp: str, c3: i64) -> bool:
    if cmp == "==": return c3 == 0
    if cmp == "!=": return c3 != 0
    if cmp == "<": return c3 < 0
    if cmp == "<=": return c3 <= 0
    if cmp == ">": return c3 > 0
    c3 >= 0

@[c_export("assert_compare")]
pub unsafe fn ctest_assert_compare(diag: c_int, cmp: *const i8, exp: c_long, real: c_long, caller: *const i8, line: c_int):
    let c = if exp < real: -1 else if exp > real: 1 else: 0
    if not ctest_cmp_holds(ctest_text(cmp), c): ctest_fail(caller, line, f"expected {exp} {ctest_text(cmp)} {real}")

@[c_export("assert_interval")]
pub unsafe fn ctest_assert_interval(diag: c_int, low: c_long, high: c_long, real: c_long, caller: *const i8, line: c_int):
    if real < low or real > high: ctest_fail(caller, line, f"{real} not in [{low}, {high}]")

@[c_export("assert_pointers")]
pub unsafe fn ctest_assert_pointers(diag: c_int, cmp: *const i8, exp: *const c_void, real: *const c_void, caller: *const i8, line: c_int):
    let a = exp as usize
    let b = real as usize
    let c = if a < b: -1 else if a > b: 1 else: 0
    if not ctest_cmp_holds(ctest_text(cmp), c): ctest_fail(caller, line, f"pointers: expected {ctest_text(cmp)}")

@[c_export("assert_bool")]
pub unsafe fn ctest_assert_bool(diag: c_int, exp: bool, real: bool, caller: *const i8, line: c_int):
    if exp != real: ctest_fail(caller, line, f"expected {exp}, got {real}")

@[c_export("assert_dbl_compare")]
pub unsafe fn ctest_assert_dbl_compare(diag: c_int, cmp: *const i8, exp: f64, real: f64, tol: f64, caller: *const i8, line: c_int):
    let d = exp - real
    let ad = if d < 0.0: 0.0 - d else: d
    let op = ctest_text(cmp)
    let c = if op == "==" or op == "!=": (if ad <= tol: 0 else: 1) else if exp < real: -1 else if exp > real: 1 else: 0
    if not ctest_cmp_holds(op, c): ctest_fail(caller, line, f"expected {exp} {op} {real}")

@[c_export("assert_str")]
pub unsafe fn ctest_assert_str(diag: c_int, cmp: *const i8, exp: *const i8, real: *const i8, caller: *const i8, line: c_int):
    let e = ctest_text(exp)
    let r = ctest_text(real)
    let op = ctest_text(cmp)
    let same = e == r
    let holds = if op == "==": same else if op == "!=": not same else if op == "=~": r.contains(e) else: not r.contains(e)
    if not holds: ctest_fail(caller, line, f"strings: '{e}' {op} '{r}'")

@[c_export("assert_wstr")]
pub unsafe fn ctest_assert_wstr(diag: c_int, cmp: *const i8, exp: *const c_int, real: *const c_int, caller: *const i8, line: c_int):
    ctest_fail(caller, line, "a wide-string assertion has no With harness")

@[c_export("assert_fail")]
pub unsafe fn ctest_assert_fail(caller: *const i8, line: c_int):
    ctest_fail(caller, line, "ASSERT_FAIL")
