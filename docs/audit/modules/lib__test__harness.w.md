# Primary verification — `lib/test/bench.w`, `runner.w`, `testing.w`

Status: **INCOMPLETE** (stale, uncompilable; filed)
Primary verifier: primary (full source reads + check execution)
Source revision: `450733e5`
Source examined: bench.w 84 lines, runner.w 33 lines,
testing.w 149 lines (each read in full)

## Scope examined

Test-harness helpers: benchmark auto-calibration (`bench.w`),
session lifecycle (`runner.w`: begin/run_test/summary),
assert/abort/skip API (`testing.w`). No callers anywhere
(`grep lib.test|lib/test`: only each other; no build.w wiring —
the `testpkg` hits are unrelated). The committed `tests/`
suites use their own local asserts.

## Behavioral matrix

- `with-stage1 check` on each: all three fail — `runner.w:12`
  (`-> void`, unknown type), `bench.w:31` (`&mut T` rejected per
  §15.1), `testing.w:141` (old `match` subject syntax). EXECUTED.
- Logic reviewed only (Go-style calibration, skip-marker
  protocol `__WITH_TEST_SKIP__`, `__FILE__`/`__LINE__` defaults):
  reads sanely, but nothing executes at HEAD.

## Findings

1. Test-harness sources stale/unreferenced — filed (same drift
   family as #1053/#1055/#1063, distinct files).

Verdict: INCOMPLETE
