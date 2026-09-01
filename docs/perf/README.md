# Performance baselines (#679)

Checked-in snapshots of the build graph's self-reported per-target
wall-time and peak-RSS measurements (`out/.build-state/build-times.tsv`,
which every run overwrites — snapshots here are the durable record).
The reference study behind the campaign lives in
`../build-perf-reference-study.md`.

## Method

- Instrumentation: per-target wall clock (c3de4c0b) + per-target peak
  RSS (ea2196d3 — `wait4` rusage for pooled children, orchestrator
  high-water delta for in-process targets).
- A **cold** baseline runs under an orchestrator whose fingerprint the
  cache has never seen (e.g. a fresh stage1), so every target executes.
- Snapshot after each phase: copy the tsv before the next phase
  overwrites it. Name: `baselines/YYYY-MM-DD-<state>-<phase>.tsv`, with
  a `#` header recording date, commit, host, orchestrator, and caveats.

## Reading the numbers

- Pooled child rows are exact `ru_maxrss` (bytes → M).
- In-process rows are the orchestrator's high-water **delta** around the
  target: `0M` means the target stayed under the existing mark, not that
  it used nothing. The TOTAL row's RSS is the orchestrator's absolute
  high-water.
- Grandchildren are invisible to a lane driver's rusage (a test lane's
  sliding-window compiler children report ~1M at the lane row).

## Campaign targets (issue #679, principled — Eric 2026-09-02)

Derived from principle, not feasibility:

- **iterate ≤ 30s** — the inner loop must not cost more than the thought
  it verifies (flow survives ~30s; 2 min kills it). Requires #684;
  interim milestone 60s.
- **battery ≤ 5 min** — verification cost must never force batching;
  every batched commit is bisection debt. Near gate: 10 min via #680 +
  fixpoint parallelization.
- **RSS: 1 GB per-target tripwire, enforced** — measured peak ~0.5 GB;
  crossing 1 GB fails the build naming the target. Raising the limit is
  a visible edit in src/main.w, never a silent creep.

Arc order (data-driven): #680 → fixpoint parallelization → #684
(promoted — it alone delivers the iterate target) → #682. The
memory-windowing arc item is cut pending #702 re-verification.

## Log

- **2026-09-01** (`ea2196d3`): first combined time×memory baseline.
  Build 195s / test 538s wall for 630s of lane work (parallelism 1.17×
  — the test phase is nearly serial; #680's prize). Orchestrator
  high-water 456M; largest child 499M — ~70× under #702's recorded
  20–34 GB, which needs re-verification (see #702).
