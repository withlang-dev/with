# Primary verification — `tools/debug_drop.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-tools-misc (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 141 lines (single complete read)

## Scope examined

Native harness driver for the debug allocator (`WITH_DEBUG_ALLOC`; see
`docs/debug-allocator.md`): `exec_capture`/`read_file` extern wrappers
(`:23`/`:27`), NUL-joined `argv4`/`argv5` (`:32`/`:35`),
`run_under_debug_alloc` (`:43`, 60 s timeout, exit code part of the
verdict per #697), `find_sub`/`line_after_prefix` (`:54`/`:74`), `run`
mode (`:95`, prints DOUBLE FREE / LEAK / clean verdict),
`check` mode (`:119`, asserts each fixture's
`//! expect-debug-alloc: <substr>` appears in the report; clean fixtures
must also exit 0). `run` mode intentionally always exits 0
(informational); `check` mode exits 1 on any failure (commit-gate lane).

## Behavioral matrix (EXECUTED vs HELD)

- EXECUTED, `with-stage1 check tools/debug_drop.w` → ok (exit 0).
  Saved: `docs/audit/probes/tools_debug_drop/check.txt`.
- EXECUTED, no-args run → `usage: debug_drop <run|check> <with-bin>
  <target.w> [more fixtures...]`, exit 2.
  Saved: `docs/audit/probes/tools_debug_drop/noargs.txt`.
- EXECUTED, `run` mode end-to-end
  (`with run tools/debug_drop.w run <seed> repro.w` on a trivial
  `print(42)` repro) → `=== debug-alloc: ... (exit 1) ===` +
  `verdict: clean (no double-free, no leak)`, exit 0.
  Saved: `docs/audit/probes/tools_debug_drop/run_trivial.txt`.
- EXECUTED, `check` mode on real corpus fixtures
  (`da_pod_vec.w` clean + `da_manual_double_free.w` DOUBLE FREE) →
  `PASS`/`PASS`, `debug-alloc lane: ok`, exit 0.
  Saved: `docs/audit/probes/tools_debug_drop/check_two.txt`.
- HELD: `check` failure exit path (no failing fixture run; would only
  re-prove the `failed > 0 → exit 1` counter, 3 lines).

## Findings

None. In-report notes (not filed):
- `run` mode does not propagate the inner repro's exit code (always
  exits 0). Deliberate: `run` is the interactive verdict printer;
  `check` is the gate and enforces `rc == 0` for clean fixtures
  (`:128`). No change needed.

Verdict: COMPLETE
