# Build-time experiment log

Task: reduce build time by efficiency only — never by destroying
functionality or test coverage. Regressions get reverted. Measurements come
from the executor's own instrumentation (`[times]` lines /
`out/.build-state/build-times.tsv`) unless noted. Companion docs:
`docs/build-perf-reference-study.md` (reference-compiler evidence), campaign
#679, decisions D13/D14.

## Baseline (2026-07-17, before the campaign)

- Full verification battery: ~40 min wall, >30 GB peak RSS, for EVERY change
  including docs. No timing instrumentation existed; this number was only
  measurable by wall-clock archaeology.

## Landed experiments (2026-07-17 → 2026-07-18 session)

| Change (commit) | Measured effect |
|---|---|
| #650 post-link version stamp (5f8ad53a) | commit-only rebuild ~12 min → 16.6 s (probe-verified) |
| Executor timing instrumentation (c3de4c0b) | 0 direct; first measurement: stage1 175.9 + stage2 174.3 + link 173.0 = 77% of 681 s `with build` |
| Test verdicts keyed on with.unstamped (4dcf9419) | restamp no longer invalidates 1876 verdicts (proven: 7 cached/0 ran after WITH_VERSION change); non-compiler commits: test leg → seconds |
| Test runner cores-width + sliding window (196056ac) | test leg ~22 min (4-wide batch) → ~8 min (16-wide) |
| `:dev` tier + D14 tiering (7d14dba4, 00e48435) | iterate loop: full battery → `with check` 92 s or seed→stage1 3 m 43 s |
| audit:all ∥ :test in battery recipe (D14) | ~6 min audit hides inside test leg |
| Stamp temp-sibling+rename (0efd2552) | robustness (self-overwrite crash window closed); 0 time |
| #680 stage A: edge audit + 29 declared edges (76c6d969, 0262e1ed) | 0 direct; unblocks concurrency; audit self-reports regressions every graph load |
| #680 stage B: allow_parallel worker pool (a2413f2e, 44ab0d26) | full chain 757.8 s → 684.2 s (~10%); object/IR tail now runs as cores/2-width waves; fixpoint stayed byte-identical |
| #681 dead strip pipeline deleted (60dc5ec9) | −221 lines; codegen_units_plan/strip/emit_one/codegen_units_emit gone (superseded by per-unit generation) |
| #681 windowed emit concurrency (0a14b07c) | memory K-cap removed — peaks are K-INDEPENDENT under full concurrency (15.3 GB @ K=5 / 13.2 @ K=8 / 14.4–15.5 @ K=16); emit threads join-oldest windowed, W = (mem − 5 GiB) / (plan_cost × 36 KB / K), calibrated plan_cost=289004 / frontend 4.9 GB; W=16 big-host baseline unchanged (149.1 s); forced W=2 footprint 10.03 → 7.76 GB at +47 % wall; 21-cell matrix pinned vs compiler.CodegenUnitsPolicy |
| #683 serial actions in-process (c81e8173) | per-action worker child (re-eval of build.w, ~0.85–1.6 s each) eliminated for serial actions: compiler-main-source 1.6 → 0.0 s, prepare-bootstrap-link-root 1.6 → 0.0 s, bootstrap-llvm-link-metadata 2.0 → 0.8 s; commit-shape rebuild 13.9 → 10.4 s (−25 %); cold build via new executor passed end-to-end (worktree). Pool children unchanged (their processes buy parallelism) |

Current state: compiler-change battery ≈ 25 min (build 684 s + fixpoint 312 s
+ max(audit, test) ≈ 8 min + evidence tails). Non-compiler commit ≈ 16 s
build + cached-verdict sweep. Iterate tier ≈ 92 s / 3.7 min.

## Where the remaining time is (measured)

- `with build` 684.2 s: stage1 190.5 + stage2 191.4 + link-compiler 189.1 =
  571 s (83%) — an inherently serial self-compile chain; scheduling cannot
  reduce it further. compiler-no-c-export 18.6 s, regex-runtime-ir 14.5 s
  (overlapped), pooled object waves.
- `:fixpoint` 311.9 s: two more object emits of the same source (141.8 +
  139.2) + bless 22.9. Cost of the byte-fixpoint invariant (kept — D14).
- `:test` ≈ 8 min at 16-wide when the compiler changed; seconds otherwise.

## 2026-07-18 — Experiment: WITH_PROFILE decomposition of the 190 s stage compile

Command: `WITH_PROFILE=1 with build out/gen/main.w -O1 -o <probe>` (seed
compiler, identical to a stage1 compile). Result (wall ≈ 180 s):

- Frontend, single-threaded, ~97 s: resolve 1.86 + imports 0.39 + comptime
  3.24 + frontend.sema 30.58 + sema 43.19 (types=9526) + mir.lower 17.83
  (bodies=6876). **Sema = 73.8 s is the largest serial block.**
- LLVM backend ~83 s wall: gen_module 14.5 (serial) + 8 parallel units where
  wall = slowest unit: unit2 67.8, unit0 60.0, unit1 39.1, then 16-28 s for
  the rest. **4.2x unit imbalance; perfect balance would be ~36 s.**
- link 0.72, dsymutil 0.24.

Conclusions: (a) the cheapest lever is codegen-unit BALANCE — the packer
bins by basic-block count, a bad proxy for -O1 cost; ~30 s recoverable per
stage compile × 5 compiles/battery ≈ 2.5 min, zero memory cost, must stay
deterministic (fixpoint). (b) After balance, the K=8 unit cap is worth
revisiting — but only after #681 drops the ~3 GB/unit parse cost, else
memory explodes. (c) Sema (73.8 s serial) is the long-term frontend target;
parallelizing it is deep work (park until the cheap levers are spent).

→ Next experiment: rebalance units on a better deterministic cost metric.

## 2026-07-18 — Experiment: codegen-unit packing by instruction count (KEPT)

Change: `wl_fn_instruction_count` in LlvmBridge.w (block/instr walk);
`codegen_units_plan` bins by instruction count instead of block count
(src/compiler/CodegenUnits.w:106). Deterministic (counts from the parsed
module).

Probe (stage1 carrying the change, profiled self-compile):
- Unit spread BEFORE: 16.1–67.8 s (4.2x), wall = 67.8 s.
- Unit spread AFTER: 25.0–50.3 s (2.0x), wall = 50.3 s.
- Per-compile: ~180 s → ~161 s (~19 s). Projected ~95 s per full battery
  (5 self-compiles). Battery-scale measurement in the gate run below.

Remaining skew (unit7 50.3 vs unit3 25.0) is a few indivisible
mega-functions dominating their bins; fixing needs more units (blocked on
#681 memory) or function splitting (not worth it). Battery + fixpoint gate
this before commit. GATED GREEN and landed (cf22186c): battery-scale
stage2 191.4→165.8s, link-compiler 189.1→167.9s (~25s each). Fixpoint
objects barely moved (140s — frontend-dominated, less backend to balance).

## 2026-07-18 — Experiment: parallelize invariance-check variants (KEPT)

Instrumentation surfaced `invariance-check` as the single longest battery
item: 468.2s — five meaning-preserving perturbation variants, each a full
~93s `check src/main.w`, run SERIALLY against one repo copy inside one
action. The variants are independent by construction (each applies to a
pristine copy), so: one target per variant (`invariance-<label>`), each
with its own repo copy under its own output dir, marked `.allow_parallel()`;
`invariance-check` becomes a Group over the five (graph edges unchanged).
Coverage identical — same five variants, same check, same failure
diagnostics (perturbed tree left per-variant for inspection).

Measured: all five retire at 103.1s (fully overlapped) — 468.2s → ~103s
wall, 4.5x, ~6 min off every compiler-change battery. Five concurrent
whole-compiler checks fit comfortably in host memory.

Side observation, logged for #686: the measurement run itself paid a
~10-min stage-chain rebuild because editing build.w invalidates the chain
(action signatures hash the build source). Every build-layer experiment
pays this tax; #686 is now the highest-leverage remaining build-graph fix.

## 2026-07-18 — Experiment: group passthrough + more pooled checks (KEPT)

Two-part batch (5ad88c76 + 70c887e5): (a) Groups no longer drain the pool
— a Group executes nothing and only propagates dep_rebuilt, and an
in-flight dep IS a rebuilding dep, so the invariance-check Group between
marked targets stopped breaking the wave; (b) issue61-regression and
embedded-runtime-regression marked allow_parallel (same pure shape as the
invariance variants).

Measured in the gating battery: one seven-wide wave — issue61 101.0s +
five invariance variants ~102s + embedded-runtime 5.1s, all overlapped.
~100s more off the test leg. Battery green, fixpoint held.

Watch item: behavior-tests read 147.7s this battery vs 109.2s earlier —
possibly contention with the wave or run variance; check next battery
before drawing conclusions.

## 2026-07-18 — Experiment: #686 scoped action signatures (KEPT)

Landed as c05c560d + 2acd23a4 after a three-layer diagnosis, each step
forced by measurement:
1. Closure mechanism (materializer records the action fn's defining file +
   use closure; cache hashes exactly those) — worked on first probe, zero
   closure misses across the graph.
2. First failure: root-defined stage-ancestor actions (empty-file writer,
   prepare-bootstrap-link-root) carried build.w's whole-build/ closure →
   relocated to build/runtime.w (closure = std.build only).
3. Second failure + the actual root cause: build/ and build.w were declared
   INPUTS of every stage target (target_with_compiler_source_inputs) —
   belt-and-braces from before scoped signatures existed. Removed; the
   stage compile never reads them.

A methodology lesson mid-diagnosis: probing with a stage1 driver while
editing src invalidates everything via the driver-fingerprint signature
component — stale-reason lines ("[stale-debug]") settled in one run what
three theories could not. Reason-printing is worth keeping in mind as a
permanent debugging surface.

Verdict, measured: benign build/emit_c.w edit = 19.7 s no-op sweep with
zero stale targets (was ~10 min stage-chain rebuild). No-edit sweep also
19.9 s and byte-stable. Every future build-layer experiment in this log
just got ~10 min cheaper — the fix that accelerates the loop itself.
Also declared the 6 fixpoint/last-green edges the graph audit surfaced on
its first pass over the test closure.

## 2026-07-18 — Experiment: 16 codegen units (NEGATIVE — no change made)

Measured via the existing WITH_CODEGEN_UNITS override, zero code touched:
max unit 56.7 s (8-unit baseline: 50.3), wall 170.9 s (vs ~161), peak RSS
30.5 GB (vs ~24), sys time 164 s — sixteen full-module bitcode parses
contend for memory bandwidth and swamp the finer split. 8 units stays the
right default on this host. Confirms #681's structural tier (pre-split the
bitcode so each unit parses ~1/K) is the only route to profit from more
units. Negative results are results; this one cost 3 minutes.

## Loop summary (2026-07-18, stopping point)

Landed this loop, all gated green, every number from the executor's own
instrumentation:
- Codegen-unit packing by instruction count: stage compiles ~180 → ~161 s
  (unit spread 4.2x → 2.0x); at battery scale stage2 −25.6 s, link −21.2 s.
- Invariance variants parallelized: 468.2 → ~103 s (5 concurrent checks).
- Group passthrough + pooled issue61/embedded-runtime: one 7-wide wave;
  ~100 s more off the test leg.
- #686 scoped action signatures + input-set fix: build-layer edit tax
  ~10 min → 19.7 s no-op sweep (the fix that made the loop itself cheaper).
- Cold full chain: 757.8 → 625.2 s (−17.5%). Reseeded; all in the driver.

Combined with the pre-loop campaign session: full verification for a
compiler change ≈ 20 min (was ~40 for everything), non-compiler commits
≈ 2 min, iterate tier 92 s / 3.7 min, and every run reports where its
time went.

The remaining items are all multi-day structural campaigns, filed with
designs and evidence — not loop-iteration-sized: sema parallelization
(73.8 s serial, the largest single block), #681 structural bitcode
pre-split, #682 prelude snapshot, #683 compiled build graph, #684 separate
compilation (the only fix for the ~170 s-per-stage constant). The
iteration-sized efficiency levers are exhausted — by measurement, not
assumption.

## 2026-07-18 — #681 campaign opened: base-module disposal (KEPT) + design

North star recorded (maintainer): after #681/#682/#683, peak build memory
UNDER 8 GB — buildable on an 8 GB machine, Mac/Linux/Windows.

Quick tier landed (88ade44f): codegen_units_emit disposes the parent's
whole-module copy right after the bitcode write (deinit() is dead code —
the module leaked until exit). Measured A/B on a stage compile: peak RSS
21.1 → ~20.0 GB; wall neutral within variance (161/166/172 s runs).
Finding: only ~1.1 GB of the ~3 GB module came back — the LLVMContext
retains its uniquing tables. That is direct evidence that the 8 GB goal
needs per-unit IR GENERATION (each thread's context holds one unit), not
disposal tuning.

Structural design confirmed feasible and specced on #681: per-thread
Codegen (own context/module + cloned InternPool — MBs; ids thread-local),
shared read-only Sema/AST/MIR via the existing raw-pointer thread
precedent, with audit:all's frozen-Sema invariant supplying exactly the
thread-safety guarantee the design needs. Gen takes `move MirModule` today
and needs a borrow variant; the 82 self.intern mutation sites are the
clone-boundary checklist. Days-class; own session with /drop-audit +
fixpoint + battery gates.

## 2026-07-18 — #681 STRUCTURAL LANDED: per-unit generation from MIR (KEPT)

The campaign's core change (a497d145 MIR-via-pointer groundwork + bc0c9832
per-unit generation). The whole-module bitcode round-trip is gone: units
are generated directly from MIR (serial, one cg alive at a time), then
threads parse ~1/K-size unit bitcodes and optimize+emit. Bring-up took two
rounds: round 1 linked-failed on duplicate synthesized prelude trait
defaults (external bodies emitted per unit) — fixed by a deterministic
post-gen demotion walk mirroring the old strip's ownership rules.

Measured (stage-equivalent compiler compile):
- Peak RSS: 21.1 GB (baseline) → 20.0 (disposal) → **13.2 GB (−37%)**
- Max unit: 50.3 s → 36.7 s (thread parse tax gone)
- Wall: neutral (~160-165 s); serial gen 23.6 s vs 14.5 s whole-module
- Gates: fixpoint byte-identical, drop-audit 25/25, 1876 tests, produced
  compiler self-checks.

Consequences: unit counts >8 are now viable (parse cost no longer scales
with units — retest 12/16 units next); the 8 GB-host architecture is in
place (remaining: frontend residency #682/#685, unit-count-vs-memory
tuning on small hosts).

## Remaining queue (updated)

1. #686 signature scoping — the ~10-min tax on every build-layer edit; now
   the single highest-leverage remaining item. Design (verified feasible,
   implement next): today every kind-23 signature includes
   build_cache_hash_build_graph_sources = hash(build.w + build/* +
   lib/std/build.w) (BuildGraphCache.w:286-290, used at :435-436). Replace
   with a per-target `action_code_hash` computed at materialize time: the
   materializer has the action fn's decl id (Materialize:155) and Sema maps
   decl -> source path (Sema.w:978 decl_source_paths); hash the defining
   file plus its `use` closure among {build.w, build/*, lib/std/build.w}
   (file-granular over-approximation of the call closure — safe, never
   under-invalidates). Probes after implementing: (a) comment-only edit to
   build/emit_c.w must leave stage1/stage2/link FRESH; (b) edit to
   build/compiler.w must invalidate stage actions; (c) build.w edit must
   invalidate only build.w-defined actions plus changed target defs.
2. Sema 73.8 s serial block (from the profile) — deep compiler work.
3. #681 codegen-unit memory (enables >8 units → further backend wall cuts).
4. #682 prelude snapshot; #683 compiled build graph; #684 separate
   compilation (endgame).

## Idea queue (from .reference study; ranked by expected value)

1. Decompose the 190 s stage compile with WITH_PROFILE (per-phase lines
   exist in Compilation.w/Backend.w) — decides whether the next lever is
   frontend (parse/sema/MIR, single-threaded) or LLVM backend. → THIS LOG,
   next entry.
2. #686: build.w-only edits rebuild the stage chain (action signature hashes
   the whole build source). Fix = scope the hash to the action's comptime
   call closure (`with analyze closure:call` can compute it). Saves ~12 min
   per build-layer iteration.
3. #681: codegen-unit windowing + dispose base module/MIR (memory, but the
   ~3 GB/unit bitcode re-parse also costs time).
4. #682: serialized prelude snapshot — O(100ms) × ~2000 child processes per
   battery.
5. #683: stop re-interpreting build.w per worker (~1.1 s minimum per action,
   measured on a trivial two-action project).
6. #680 stage C: delegate remaining in-process kinds (regex-runtime-object
   3.7 s, bridges) through the pool (~8 s bound).
7. #684: separate compilation with module interfaces — the only fix for the
   571 s serial chain. Endgame.
8. regex-runtime-ir built twice per cold chain (bootstrap+normal legs, ~14 s
   each) — different compilers (seed vs stage2) make them legitimately
   distinct today; unifiable only at fixpoint. Low value; revisit after 2.
