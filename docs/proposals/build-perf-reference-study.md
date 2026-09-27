# What Go, Rust, Swift, Vale, and Zig Do Right That With Does Wrong

(Multi-agent study, 2026-07-17. 7 source surveys — go/rust/swift/Vale/zig +
With build/memory anatomy — distilled to 11 candidate deltas; each delta
adversarially verified against both source trees; 10 confirmed, 1 refuted.
All file:line references were independently checked. UNCOMMITTED — maintainer
decides whether this doc stays.)

## Executive Answer

The references stay under 8 GB and 10 minutes because of three architectural
choices With inverted. First, **they bootstrap rarely and iterate on one
compile**: Rust's `x build` defaults to stage 1 (config.rs:1103-1105), Zig's
dev loop is a single ~20-second self-compile with the stage3==stage4 byte diff
confined to release CI (README.md:528-534, ci/*-release.sh), and Go runs its
3-stage chain only in make.bash with convergence carried by content-keyed
caching (buildid.go:58-66) — while With runs 5 whole-program ~160k-line
self-compiles on every verification (build.w:1263-1334). Second, **they bound
backend memory with explicit backpressure**: Zig caps in-flight AIR at 10 MiB
(Zcu.zig:5226-5232), Rust's coordinator throttles IR production and frees each
LLVM module at worker exit (write.rs:1839, :1409-1412), Go pools backend
concurrency with tokens (gc.go:184-255) — while With spawns ALL K codegen-unit
threads at once, each re-parsing the full ~3 GB module bitcode, with a sizing
formula `(mem_gb-6)/3` that grows peak memory with host RAM instead of
bounding it (CodegenUnits.w:57-78, :243-254). Third, **they key caches on
semantic content and schedule at core width**: Go's test cache hashes binary
content plus actually-read inputs (test.go:1569-1578) and Zig skips a Run step
on content-manifest hit (Run.zig:876-941), at GOMAXPROCS/all-cores width —
while With fingerprints the version-stamped binary so every commit invalidates
all 1,876 banked test verdicts (BuildGraphCache.w:370-377, build.w:1512), then
runs tests 4-wide with a batch barrier on a 16-core machine
(BuildGraphTests.w:66-73, :156-181). The monolithic whole-program compilation
unit (no interfaces, no per-module objects — Frontend.w:1674-1701 vs. Go's 48
packages, Rust's 75 crates against .rmeta) is the long-term structural gap,
but the first three differences account for most of today's 40 minutes and
30+ GB. None of the fixes require abandoning self-hosting, -O1, byte-level
fixpoint, or the no-external-deps invariant — the references prove each
guarantee survives at a coarser tier.

---

## Confirmed Deltas, Ranked by Impact

### 1. Five self-compiles per verification; references iterate on one

**They:** Rust `x build` defaults to stage 1 — one self-compile — with full-
bootstrap reproducibility explicitly documented as "only useful for verifying
that rustc generates reproducible builds" (src/bootstrap/src/core/config/
config.rs:1103-1105; bootstrap.example.toml:386-392). Zig's post-change loop
is `stage3/bin/zig build -p stage4`, "about 20 seconds," with the
byte-for-byte stage3/stage4 diff run only in the 11 `ci/*-release.sh`
scripts, never in the dev loop (README.md:528-534). Go runs toolchain1/2/3
only inside make.bash (cmd/dist/build.go:1498-1598) and then primes the cache
"so that the user can... quickly iterate on local changes"; convergence is an
argued cache-key property (cmd/go/internal/work/buildid.go:58-66), and the
full re-bootstrap test is skippable (reboot_test.go:23-24). Swift's default
is zero self-compiles (HOSTTOOLS, CMakeLists.txt:377-387); Vale's compiler
core never self-hosts.

**We:** Default `with build` = 3 whole-program compiles of the same
out/gen/main.w — stage1 by seed (build.w:1263-1280), stage2 by stage1
(:1282-1293), link-compiler by stage2 (:1438-1448) — and `:fixpoint` adds 2
more `--emit-obj` recompiles of identical (compiler, source) pairs
(:1308-1334). All five take every .w under src/ as inputs (build.w:141-154),
so any one-byte change reruns the entire chain: ~11 min of stages+link plus
~5 min of fixpoint, measured from artifact mtimes of today's battery.

**Adopting it:** A dev-tier default target (seed→stage1 only) in build.w,
with the full chain plus fixpoint mandatory at commit/:update-seed/release
tier. This is a policy decision — the maintainer's, not an agent's — but
implementation is a few lines.

**Effect:** ~3-5x on the build leg per iteration (~16 min → ~3-5 min). The
single biggest wall-time lever that needs zero compiler changes.

### 2. Unbounded codegen-unit fan-out; references throttle backend memory

**They:** Rust's coordinator keeps the codegen queue "just full enough"
(`queue_full_enough`, write.rs:1839; `wait_for_signal_to_codegen_item`,
:2291), rejects largest-first CGU ordering because it "would lead to high
memory usage" (base.rs:724-741), and frees each LLVM module when its worker
exits (write.rs:1409-1412). Zig caps in-flight AIR at 10 MiB with producer
backpressure — the producer literally waits on a condvar until the linker
catches up (Zcu.zig:5226-5232, :5312-5315). Go caps backend concurrency with
a token pool (work/gc.go:184-255).

**We:** `codegen_units_emit` spawns ALL K unit threads unconditionally
(CodegenUnits.w:243-254), each re-parsing the FULL whole-module bitcode into
a private LLVMContext at a source-documented ~3 GB per unit (:57-61), while
the parent keeps the un-disposed base LLVM module, AST, Sema, and MIR live
(Backend.w:66-69). The formula K = min(cores, 8, (mem_gb-6)/3) (:71) fits RAM
but never sets an absolute budget: K=8 ≈ 24 GB of LLVM on top of the ~2.5 GB
frontend — consistent with the ~31.7 GB peak (that specific number is an
external observation; the arithmetic is in-source).

**Adopting it:** Quick tier — window spawns to W in flight and dispose the
base module (and MIR) before fan-out; audit Backend.w:66's post-codegen
`last_mir_module` read first. Structural tier — split bitcode per unit BEFORE
spawning so each thread parses ~1/K of the module, killing the 3 GB constant.
Rust's write.rs comments are the design doc.

**Effect:** The main lever on the >30 GB peak. W=4 with a freed base module ≈
~14-17 GB; the structural tier takes it well under 8 GB.

### 3. Test verdict cache keyed on the stamped binary — defeats our own D13

**They:** Go's test cache key is binary content + args + a log of every
file/env the test actually read — with an explicit comment that "if we have
different link inputs but the same final binary, we still reuse the cached
test result" (test.go:1569-1578, :1793, :1879-1881). Zig's Run-step manifest
hashes exe content, argv, stdin, and inputs, then prints "cache hit, skip
running command" (Run.zig:876, :926-941).

**We:** `build_cache_test_compiler_fingerprint` content-hashes the compiler
path (BuildGraphCache.w:370-377), and every verdict-cached test target passes
`compiler=out/release/bin/with` (build.w:1512 and 8 siblings) — the binary
that the `build` target byte-patches with the git HEAD hash and re-codesigns
on every commit (build/compiler.w). So all 1,876 banked verdicts are
invalidated per commit even when `with.unstamped` is byte-identical. D13
(docs/decisions.md) made the stage chain commit-independent; this key defeats
it for exactly the longest phase.

**Adopting it:** Fingerprint `with.unstamped` (or mask the fixed-width
version region) in BuildGraphCache.w, or point test targets' fingerprint at
the unstamped output. A few lines. Verify a commit-only change hits every
verdict.

**Effect:** For commit-identity-only or non-compiler changes, the test leg
drops from a full re-run to a seconds-long verdict sweep. Largest single
per-commit wall-time win. Zero memory effect.

### 4. Tests run 4-wide with a batch barrier; references run at core width
with sliding windows

**They:** Go: -p = GOMAXPROCS (cfg.go:87). Rust compiletest: thread-per-test
at `available_parallelism`, refilling each finished slot via a completion
channel (executor.rs:24-93, :316-325). Swift lit: -j = cpu_count
(driver_arguments.py:440). Zig: all cores (build_runner.zig:1643). Even Vale
— the weakest reference — uses a sliding window that joins one before
spawning the next (Tester/src/main.vale:441-446), never a batch barrier.

**We:** Default 4 jobs on this 16-core host (BuildGraphTests.w:66-73), and
the scheduler spawns a batch then joins ALL of it in spawn order before
refilling (:156-181) — one slow file idles up to 3 workers per batch. Test
targets additionally run serially one after another in the executor
(main.w:1570, :1633-1678).

**Adopting it:** Default jobs = host cores via with_sysinfo (keep
WITH_BUILD_TEST_JOBS as override); replace join-all with join-any-refill in
`build_graph_run_external_test_files`. Localized to BuildGraphTests.w.
Sanity-check N × per-test RSS against host RAM (each child already carries
its own 32 GiB cap).

**Effect:** ~3-4x on the test leg when it actually runs. Note the test leg's
duration is itself uninstrumented (see delta 10) — "~15-20 min" is plausible
but unmeasured.

### 5. Monolithic whole-program compilation unit; references compile many
units against serialized interfaces

**They:** Go cmd/compile = 48 packages, process-per-package, deps consumed as
mmapped lazily-decoded export data (noder/import.go, base/mapfile_mmap.go).
Rust = 75 crates compiled against .rmeta as a parallel process DAG
(rustc_metadata/src/rmeta/). Swift = 37 per-subsystem static libs over 968
TUs under ninja. Vale = 3 process-isolated components with on-disk .vast
handoff (Coordinator/src/valestrom.vale, midas.vale). Rebuild cost = changed
subgraph; peak RSS = max-unit, not sum.

**We:** Every stage is ONE child process compiling ONE merged ~160k-line
program: out/gen/main.w's use-graph parses into a single AstPool
(Frontend.w:1674-1701), and the cache signature hashes ALL src .w files
(BuildGraphCache.w:430-437), so any one-byte change re-runs every
self-compile end-to-end. The codegen units are intra-compile objects, not
cached module units. No interface artifacts exist anywhere.

**Adopting it:** Structural, months: serialized module interface data (the
flat SoA i32 AstPool/Sema tables are unusually friendly to raw dump/mmap),
per-module compile targets in build.w, cross-module resolution at link.
Converts rebuild cost from O(compiler) to O(change) and peak memory from
sum-of-program to max-of-module — but delivers nothing until the whole
pipeline exists. Deltas 6 and 7 below are its prerequisites.

**Effect:** Order-of-magnitude on warm iteration, long-term. This is the
endgame, not the first move.

### 6. Every process re-frontends the prelude; references never re-typecheck
(or even re-parse) unchanged deps

**They:** Zig caches per-file ZIR on disk globally per machine per compiler
version, stat-gated with cross-process locking — stdlib AstGen happens once
per compiler version per MACHINE (Zcu/PerThread.zig:483-700, global cache
routing at :507-510). Go mmaps lazy export data; Swift loads definitions by
name from indexed binary .swiftmodules (ModuleFileSharedCore.h:272-318); Rust
compiles against .rmeta. (Zig still re-runs Sema over used stdlib; its cache
covers lex/parse/AstGen only.)

**We:** Every compile re-lexes/parses/semas the std.prelude transitive
closure from embedded source — 13 modules, ~71 KB unconditional
(Resolve.w:185-201, Frontend.w:1333-1376) — in EACH of the ~2000 test child
processes, every stage compile, and every build worker. No serialized
AST/Sema artifact exists in the codebase.

**Adopting it:** Structural but self-contained: a versioned, mmap-able
serialized prelude snapshot (AST pool + Sema tables) keyed by compiler
fingerprint, Zig-style, loaded at prelude injection. Ship it for the prelude
alone first — it has the highest reuse count in the system.

**Effect:** A constant tax times ~2000+ invocations per battery; even
100-200 ms per process is minutes of pure redundancy. Also the enabling
prerequisite for delta 5.

### 7. Grow-only heap that never returns memory; references scope or return
it deliberately

**They:** Go sets a named 128 MB starting-heap goal for its compiler
(gc/main.go:89-93, base/startheap.go:59) and mmaps import data and linker
output so bytes live in page cache, not heap (noder/import.go:256-260,
ld/outbuf.go:32-66). Zig scopes scratch to an arena per analysis unit that
dies with the unit (PerThread.zig:1150, :1267, :1390, et al.). Vale's JVM
frontend exits — returning its entire heap — before the backend starts
(build.vale:434-451, :491): peak = max, not sum.

**We:** `free_small_block` pushes to a freelist and never munmaps
(rt/rt_core.w:585-591); only >4 KiB allocations return to the OS (:1096,
threshold at :332). Every process's small-object RSS is its lifetime
high-water mark. The whole-program tables are grow-only by construction:
AstPool raw-alloc never freed (Ast.w:545-546), Sema is one 450-field struct
(Sema.w:355-1014), the intern arena is "never freed or moved" by design
(InternPool.w:33-34). Worker process exit is the only mechanism that returns
small-object memory.

**Adopting it:** First tier — release empty slabs via
madvise(MADV_FREE)/munmap in rt_core.w, testable with the debug allocator's
committed-bytes counter. Second tier — phase-lifetime arenas (drop the AST
pool after MIR lowering); the SoA design makes reset = drop the backing vecs.

**Effect:** Recovers GBs of *concurrent* RSS during the battery, when driver
+ workers all sit at their high-water marks simultaneously. Feeds delta 2's
numbers.

### 8. Strictly serial build-graph executor; references schedule the DAG at
core width

**They:** Go's Builder.Do runs the action DAG with a ready queue at
-p=GOMAXPROCS (work/exec.go:73, :120-132). Zig's build runner dispatches
steps concurrently with max_rss ADMISSION CONTROL — steps park until their
declared memory claim fits the budget (build_runner.zig:1419-1438). Swift
rides ninja's edge-parallel scheduling.

**We:** `run_build_graph` is a single for-loop over targets in declaration
order (main.w:1570); deps drive only cache staleness (:1592-1598), never
scheduling. The 13 runtime objects (build.w:93-106), bridge objects, and
test targets run back-to-back on one core. `lib/std/build.w:627` already
ships `parallel()` — the compiler's own build never calls it.

**Adopting it:** Moderate: topological ready-queue plus windowed process
pool in run_build_graph, with a per-target memory claim checked against a
host budget before dispatch (Zig's max_rss pattern is the model for staying
under the 32 GiB caps). No cache-format changes needed.

**Effect:** Modest alone (~1-3 min — the stage chain is inherently serial),
but it MULTIPLIES delta 5: separate compilation is pointless without a
parallel executor.

### 9. Build logic reinterpreted per target; references compile their build
orchestrator once

**They:** Zig compiles build.zig ONCE into a content-cached native
build_runner binary and runs it (src/main.zig:4952, :5293-5326, :5523-5534).
Go's orchestrator is the compiled cmd/go binary over declarative go.mod.

**We:** build(ctx) and every action run through the comptime interpreter,
and each stale action/test target spawns a worker that re-compiles build.w +
prelude and re-runs build(ctx) before evaluating its single action
(main.w:1322-1356, rationale comment at :1424-1428), with each eval
deep-cloning the Sema type tables (Sema.w:1294-1320). Only process exit
reclaims the accumulated clones.

**Adopting it:** Moderate: serialize the evaluated graph once per build —
the Action cache signature already hashes build.w source
(BuildGraphCache.w:428-429), so the invalidation key exists — and have
workers load it instead of re-frontending. Zig's AOT build runner is the
endpoint.

**Effect:** Low single-digit minutes plus hundreds of MB of driver RSS
today; grows linearly with the target graph, which deltas 5/8 will grow.

### 10. Zero timing instrumentation; every reference measures itself

**They:** Cargo has --timings (flags.rs:261) and bootstrap per-step
duration+CPU metrics (metrics.rs:151-246); Go has -x/-debug-trace with
per-action traceviewer spans (exec.go:74,148); Zig's build runner collects
per-step PEAK RSS via `request_resource_usage_statistics` (Step.zig:62,
:474, :497) with live progress.

**We:** Not one clock read exists in build.w, build/*.w, or the BuildGraph
modules (the only with_clock_nanos wrapper there is dead code,
BuildGraphRuntime.w:107). The compiler's WITH_PROFILE per-phase lines exist
(Compilation.w:29-42, Backend.w:46-93) but the build never sets, captures,
or persists them. The only numbers in the system are timeouts. Nobody can
say where the 40 minutes goes without archaeology — which is why two
magnitude figures in this report are estimates.

**Adopting it:** Quick win, do FIRST: with_clock_nanos around target
dispatch, child rusage capture, one summary line per target, persisted to
out/.build-state beside the verdicts. A day of work in With.

**Effect:** Zero direct minutes — but it converts every other delta's
estimate into a measurement and catches regressions permanently.

---

## Do This Now vs. Structural

**Now (days, in order):**

1. **Timing + peak-RSS per target** (delta 10) — instrument before
   optimizing, so every subsequent win is measured, not estimated.
2. **Unstamped-binary test fingerprint** (delta 3) — a few lines in
   BuildGraphCache.w/build.w; restores D13's intent for the longest phase.
3. **Test jobs = cores + sliding window** (delta 4) — localized to
   BuildGraphTests.w.
4. **Codegen-unit spawn window + dispose base module/MIR before fan-out**
   (delta 2, quick tier) — the memory fix; audit Backend.w:66 first.
5. **Dev-tier build target** (delta 1) — seed→stage1 for iteration, full
   chain + fixpoint at commit/:update-seed/release. This one is the
   maintainer's policy call; everything needed is a target definition in
   build.w.

These five plausibly take the per-iteration battery from ~40 min / >30 GB to
under ~10 min / under ~15 GB with no compiler-architecture changes.

**Structural (weeks to months, in dependency order):**

6. **Per-unit bitcode pre-splitting** (delta 2, structural) — removes the
   3 GB/unit constant; gets peak under 8 GB.
7. **Empty-slab release, then phase-scoped arenas** (delta 7).
8. **Parallel build-graph executor with memory admission** (delta 8) —
   prerequisite-multiplier for 10.
9. **Serialized prelude snapshot** (delta 6), then **serialized build
   graph** (delta 9).
10. **Separate compilation with module interfaces** (delta 5) — the
    endgame; sequence it last because it delivers nothing partial and
    everything above multiplies it.

---

## What NOT to Copy

**Rust's downloaded stage0.** Rust's "one self-compile" works because a
downloaded beta binary compiles stage 1 (config.rs:1103-1105). With's seed is
self-produced and the toolchain must depend on nothing external after
bootstrap — keep the seed chain; copy only the *tiering*, not the binary
download.

**Swift's HOSTTOOLS.** Zero self-compiles means the compiler never eats its
own output. That is the abandonment of self-hosting, not an optimization of
it.

**Go's argued-not-asserted convergence.** Go never byte-diffs an independent
recompile anywhere in its default flow — convergence is a comment in
buildid.go and a stdout-text re-bootstrap test. With's byte-level fixpoint is
a strictly stronger guarantee and has caught real nondeterminism; keep it.
And note the instructive refutation from this study: Zig's release CI builds
an entire extra stage4 ReleaseFast compiler solely to diff it
(ci/*-release.sh) — arguably more redundant work than With's two -O1 object
recompiles. The references do not prove fixpoint-checking is wasteful; they
prove it belongs at the release/commit tier, not in the inner loop.

**Ninja, cmake, or any external orchestrator.** Swift's parallelism is
outsourced to ninja. With's answer is a parallel executor in src/main.w
written in With — the no-non-With-code invariant is not negotiable, and
lib/std/build.w:627's `parallel()` shows the machinery already exists
in-language.

**Go's GC-tuning approach to memory.** AdjustStartingHeap (startheap.go:59)
is a garbage-collector heuristic with documented failure modes (overridden by
GOGC, bypassed at -c=1). With's allocator needs slab release and arenas, not
a GC-boost analogue.

**Vale's fixed-width window and sequential components.** Vale's tester
hardcodes concurrency 10 regardless of cores and joins oldest-first
(main.vale:151, :441-446); its Scala frontend is whole-program per
invocation. Vale is the ownership-model reference, not a build-performance
one.

**Zig/Go cache-scope quirks.** Go disables test caching entirely in
local-directory mode (test.go:1794-1802) and Zig bypasses caching on
`hasSideEffects` — when the verdict cache is rekeyed, keep With's stricter
behavior (only passes cached, failures always re-run, run-all-report-all)
rather than importing either escape hatch.

**Anything that touches -O1.** No reference's speed comes from disabling
optimization in the verified artifact, and none of the ten deltas above
requires it. The wins are scheduling, caching, tiering, and memory
discipline — the optimizer setting stays where it is.
