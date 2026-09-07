# Primary verification — `lib/std/time.w`

Status: **COMPLETE** (one execution-verified finding, no issue filed per task scope)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 45 lines (single complete read)

## Scope examined

Time facade over runtime: `with_time_now` (wall epoch sec), `with_clock_nanos`
(monotonic ns), `with_nanosleep`, `with_usleep` externs (`:6-9`); private
`type Duration = i32` (`:12`) with private ctors `millis`/`from_millis`/
`seconds`/`from_secs`/`minutes` (`:17-25`); pub `now` (`:28`), `sleep_secs`
(`:32-33`, `secs * 1e9` ns), pub async `sleep(d: Duration)` (`:36-37`,
`d * 1e6` ns), pub `now_ns` (`:40-41`) and `clock_ticks` (`:44-45`, identical
body). Runtime: `rt/rt_core.w:3538-3551` (thin `rt_wall_clock_sec`/`rt_clock_ns`/
`rt_nanosleep` wrappers). Callers: `lib/test/bench.w:46,51` (`now_ns`),
`examples/async-auction.w:52` (`sleep(Duration.millis(500)).await`),
`test/behavior/behav_time_now_epoch.w` (`now`, `now_ns`).

## Behavioral matrix (EXECUTED vs HELD)

- `docs/audit/probes/time/now_epoch.w` (EXECUTED): `now()` printed `1788531470`
  vs independent python3 `time.time()` oracle `1788531464` in the same run
  window (6 s apart, both whole epoch seconds — match); `now_ns()` monotone
  `b >= a`; `clock_ticks() >= a`. PASS.
- `docs/audit/probes/time/sleep_blocks.w` (EXECUTED): `sleep_secs(1)` returned 0
  with monotonic delta `1000063532` ns (~1.0001 s, inside the 0.9–5 s
  window — refutes no-op and 1000x ms/s unit slips). PASS.
- `docs/audit/probes/time/sleep_i32_literal.w` (EXECUTED, refutation probe):
  `sleep(100).await` in `async fn main` returned 0 with delta `100080244` ns
  (~100.08 ms). PASS — the async path works.
- `docs/audit/probes/time/duration_ctors.w` (HELD — unexecutable, see Finding 1:
  `Duration` and all five ctors are module-private, so no external probe can
  name them; the file as written fails check with `symbol 'Duration' is
  private`).
- `with check lib/std/time.w` → ok (stage1).
- Repo test re-run verbatim: `behav_time_now_epoch` prints `ok`. PASS.

## Findings

1. **`Duration` ctors are unreachable from outside `std.time`, breaking the
   sole documented construction path** (execution-verified; NOT filed per
   task scope). `type Duration = i32` (`:12`) and all five ctors (`:17-25`)
   lack `pub`, yet pub async `sleep(d: Duration)` demands a `Duration` and
   `examples/async-auction.w:52` spells `sleep(Duration.millis(500)).await`.
   Observed: `with check examples/async-auction.w` fails with
   `error: symbol 'Duration' is private to module '<embedded-std>/std/time.w'`
   at `:52:11`; a `use std.time.Duration` + `Duration.millis(500)` probe
   fails the same way. Refutation attempt (does this make `sleep`
   uncallable?): NO — `sleep_i32_literal.w` proves `sleep(100).await` with a
   raw `i32` literal typechecks and sleeps ~100.08 ms, since `Duration` is a
   plain `i32` alias. So the defect is narrower than "sleep is dead": the
   named constructors are dead surface externally and the example is red.
   Likely fix: `pub` on the type + ctors (or on `millis`/`seconds` only).
   (The auction file has a second, unrelated error at `:136:31`
   `use of moved value`; out of scope for this module audit.)

In-report notes (not filed):
- `with_usleep` (`:9`) is declared but never called from `time.w` — dead
  extern decl; harmless (rt-internal and `BuildGraphRuntime` use the same
  symbol separately).
- `clock_ticks` (`:44-45`) is a byte-identical duplicate of `now_ns`
  (`:40-41`); duplication, not a defect.

Verdict: COMPLETE
