# Pre-Phase-D Implementation Plan

Status: completed plan archive. All pre-Phase-D work required for Phase D D1
was completed before Phase D implementation began.

Historical status at time of active use: implementation plan for work that
must complete before Phase D (D1) begins. This document was the contract for
pre-D work. It is not part of Phase D itself; everything here landed before the
first D1 commit.

## 1. Purpose

The Phase D design (`docs/completed/phase-d-design.md` v2) has been reviewed and
sharpened, but it cannot be implemented directly. Several open questions
need source-level investigation, several design refinements need concrete
shape, and several regression-coverage gaps need filling so D1 can detect
behavior changes.

This document enumerates that pre-D work. Each section names a deliverable,
the question it answers, and its done criteria. Some sections produce
revisions to `docs/completed/phase-d-design.md`. Some produce new audit documents.
Some land code (tests, isolated refactors). All complete before D1.

The bar is the same as Phase C: no implementation begins on a slice until
its design is complete and its prerequisites are landed. The cost of
catching a design issue at this stage is one document revision; the cost
of catching it during D1 implementation is a session.

## 2. Deliverables Summary

Before D1 implementation begins, the following must exist:

- `docs/completed/phase-d-design.md` v3, incorporating all review feedback from v2.
- `docs/audits/comptime-eval-audit.md`, answering the three ComptimeEval
  questions with source-level evidence.
- `docs/audits/parallel-state-audit.md`, enumerating current global
  compiler state with parallel-safety strategies.
- `docs/audits/build-script-survey.md`, inventorying current build.w and
  action call sites for compatibility planning.
- `docs/design/capability-dispatch.md`, specifying the mechanism by which
  user-level capability method calls reach compiler-internal implementations.
- `docs/design/build-options.md`, the concrete design of the unified
  BuildOptions struct and CLI integration plan.
- Behavior regression tests covering the current build.w and action runner
  semantics (committed to `test/behavior/`).
- An isolated refactor of `src/main.w` that separates the action-runner
  dispatch code from surrounding driver logic, producing a clean cut point
  for D1.
- A documented verification baseline (commit hash, suite passing state)
  recorded in `docs/audits/pre-d1-baseline.md`.

## 3. P1: Design Doc v3

Revise `docs/completed/phase-d-design.md` from v2 to v3 incorporating the v2 review.

### Required changes from v2

1. **Interpreter-only execution becomes the implementation strategy, not
   the doctrine.** Replace the "Native compilation of comptime functions
   is not used" paragraph with:

   > Capability-bearing comptime is implemented by interpreting MIR with
   > capability-aware intrinsic dispatch. This is the implementation
   > strategy for Phase D. If interpretation becomes a measured bottleneck
   > in later phases, native compilation may be added as an optimization;
   > the public semantics (capability dispatch, message loop, suspension
   > behavior) remain evaluator-based regardless.
   >
   > Capability methods themselves execute at native speed because their
   > implementations are compiler-internal native code. Interpretation
   > overhead applies only to user logic between capability calls.

2. **Re-slice D1-D5 to D1-D6.** Replace v2's §13 with:

   - D1: Capability-bearing comptime evaluator (build.w + actions
     in-process; no message loop required).
   - D2: BuildOptions / CLI unification only.
   - D3: Sequential Workspace skeleton.
   - D4: Message loop (with cooperative suspension).
   - D5: Generated-source generations.
   - D6: Parallel workspaces.
   - D7: Migrate existing project actions to workspaces (was D4 in v2).
   - D8: DeclSummary-driven tooling use case (was D5 in v2).

   Each slice answers one question. Suspension support belongs in D4, not
   D1. Parallel workspaces are last among the API slices because they
   require the global-state audit.

3. **Incomplete interception becomes an error, not a warning.** Replace
   the §8 backpressure paragraph:

   > If `begin_intercept` is active and the comptime function returns
   > without calling `end_intercept`, the driver reports this as a build
   > script error unless the workspace had already delivered Complete or
   > Error. Compiler orchestration cannot be silently abandoned.

4. **LinkCommand authority is bounded.** Replace §10's "any executable
   path" paragraph:

   > A Workspace may modify `args`, `cwd`, `env`, `inputs`, and `outputs`
   > of the planned link command. The replacement must preserve declared
   > outputs (`outputs` must be a superset of the original). Changing the
   > `linker` executable to a different path requires either an explicit
   > ProcessCap or a future LinkCap; the Workspace capability alone does
   > not grant arbitrary executable invocation authority.

5. **Comptime entry point compatibility.** Add to §4:

   > Existing `pub fn build(ctx: BuildCtx) -> Build` remains accepted. A
   > function whose parameter list includes a capability type is treated
   > as a capability-bearing comptime entry point when invoked by the
   > driver. Explicit `comptime fn` marker syntax is optional during
   > Phase D; it may be required in a later phase if disambiguation
   > becomes necessary.

6. **Symbol id stability caveat.** Add to §4 under "Function Identity":

   > Internal symbol ids are session-local. Graph output, cache keys, and
   > any cross-session persistence must use stable identifiers
   > (qualified name plus signature hash), not allocation-order symbol
   > ids.

### Audit findings integration

Incorporate the findings from P2 (ComptimeEval audit) into §3 of the
design doc. Replace the three open questions with the answers and the
concrete extension plan.

Incorporate the findings from P3 (parallel state audit) into §11 of the
design doc. Replace the illustrative enumeration with the authoritative
one.

### Done criteria

- v3 contains all six required changes from above.
- v3 incorporates P2 and P3 audit findings.
- v3 passes a re-review pass before D1 begins.
- v2 is preserved at `docs/archive/phase-d-design-v2.md` for reference.

## 4. P2: ComptimeEval Audit

Audit the existing comptime evaluation infrastructure and produce
`docs/audits/comptime-eval-audit.md` with source-level evidence.

### Files to read

- `src/ComptimeEval.w` — the evaluator
- `src/ComptimeTransform.w` — comptime-driven transforms
- `src/Sema.w` — comptime type rules and the `is_ci_visible` mechanism
- `src/MirLower.w` — comptime MIR construction
- `lib/std/compiler.w` — existing capability types and `__driver_new`
  constructors
- `src/main.w` — current driver dispatch to build.w and action runners

### Questions to answer

For each question, the audit must cite specific files and line ranges,
not summaries.

**Q1: Can the current ComptimeEval evaluator invoke functions that take
capability-typed parameters?**

Concretely: if a function has signature
`fn f(token: str, root: str) -> i32` and is called from a comptime
context with arguments, does the evaluator handle the call correctly?
Does the evaluator distinguish parameter types in any way that would
break with capability types (which are structs containing tokens)?

**Q2: Can the evaluator dispatch effectful operations from inside
evaluation?**

The existing `BuildCtx.__driver_new` and similar capability constructors
suggest there's already some compiler-internal dispatch path. Document
that path. Specifically: when user code calls `ctx.fs().read_text(path)`,
what's the chain from comptime evaluation to the compiler's filesystem
implementation? Does this path go through native code execution (the
generated runner binary), or through evaluator intrinsics, or both?

**Q3: Can the evaluator suspend execution at a defined point and resume
with a value provided by the caller?**

This is the question that determines whether D4 (message loop) requires
new evaluator work. Currently, comptime evaluation runs to completion
without yielding. Determine: does ComptimeEval have any existing
suspension mechanism (for I/O, for evaluator-bounded recursion, for
anything)? What would adding cooperative yield-and-resume require?

### Done criteria

- All three questions answered with file paths and line ranges.
- Each answer includes a concrete plan for extension if the current
  state is insufficient.
- The audit explicitly states whether D1 can proceed with the current
  evaluator or requires extension work before D1 starts.
- The audit recommends which D-slice owns each extension (D1 for
  capability dispatch if needed; D4 for suspension).

## 5. P3: Parallel State Audit

Enumerate all global compiler state and specify the parallel-safety
strategy for each. Produce `docs/audits/parallel-state-audit.md`.

### Required enumeration

For each item: current state (global / per-Zcu / per-Compilation /
thread-local), mutation pattern (monotonic / replace / arbitrary), and
parallel-safety strategy (stays global with synchronization / becomes
per-workspace / stays global because immutable / other).

Items known to need handling:

- Intern pool (currently global, monotonic)
- Parsed module cache (currently global, monotonic)
- Zcu / Compilation state (currently global, arbitrary mutation)
- Diagnostic emitter (currently global, append-only)
- Embedded stdlib cache (currently global, read-only)
- LLVM context (currently global, arbitrary)

Items that may exist and need investigation:

- Generated source path counter / temp file naming
- ToolFs write scope tracking
- ProcessRunner state
- Build graph evaluation order tracking
- Selfcheck stage cache
- PCRE2 reference download state
- Any HashMap iteration that affects output

### Methodology

Grep the compiler source for `var ` declarations at module scope.
Grep for `pub fn` returning singletons (anything that looks like
`get_*_instance()` or `*_state()`).
Grep for `extern fn with_*` calls that touch process-global state
(stdout, stderr, env, file descriptors).
For each found item, classify and document.

### Done criteria

- Authoritative enumeration of compiler global state.
- For each item, parallel-safety strategy named with one-sentence
  justification.
- List of items that block D6 (parallel workspaces) until refactored.
- Estimated complexity for each refactor (small / medium / large).

## 6. P4: Capability Dispatch Design

Specify the mechanism by which user-level capability method calls reach
compiler-internal implementations. Produce `docs/design/capability-dispatch.md`.

### Questions to answer

**Q1: How are capability types identified by the compiler?**

The compiler needs to know that `BuildCtx`, `Workspace`, `ToolFs`, etc.
are capability types so it can mint them and dispatch their methods
specially. Is this:
- A naming convention (any type with `__driver_new`)?
- An attribute (`@[capability]`)?
- A trait (`impl Capability for BuildCtx`)?
- A position in `std.build` / `std.compiler` modules?

Recommendation expected, with rationale.

**Q2: How does the comptime evaluator route capability method calls?**

When evaluation reaches `workspace.compile()`, what happens?
- Does the evaluator interpret the method body?
- Does it detect that `compile` is a capability method and dispatch to
  a compiler intrinsic?
- How is the dispatch table populated?

The answer affects what `lib/std/build.w` looks like. Capability methods
might be:
- Ordinary With functions whose body calls a compiler builtin (similar
  to how `print` calls `with_print_str`).
- Method declarations with no body, recognized by the compiler as
  intrinsic stubs.
- Something else.

**Q3: How is the capability token validated on each call?**

Token validation is the security boundary. Specify:
- Where the expected token lives (per-workspace? per-capability-instance?).
- When validation happens (every call? once at evaluator entry?).
- What violation looks like (panic? structured error? evaluator abort?).

**Q4: How are new capabilities added in future phases?**

The mechanism should allow adding `LinkCap`, `NetworkCap`, etc. without
re-architecture. Specify the extension path.

### Done criteria

- Each question answered with a concrete design.
- The design specifies the public surface (what `lib/std/build.w`
  declarations look like) and the compiler-internal surface (where the
  dispatch table lives, how it's populated).
- The design is consistent with the audit findings from P2.

## 7. P5: BuildOptions Concrete Design

The unified BuildOptions struct and CLI integration plan deserves its
own design document because it's the largest refactor in D2 and touches
the entire CLI surface. Produce `docs/design/build-options.md`.

### Required content

**Current state survey.** List every CLI flag accepted by `with build`
today, with its effect. Group by category (output, optimization, target,
prelude, includes, defines, libs, migrator-specific, debug). This is the
authoritative source for what BuildOptions must cover.

**Field-by-field BuildOptions specification.** For each field:
- Name and type.
- Default value.
- Which CLI flags set it.
- Which workspace methods read it.
- Validation rules.
- Cross-field constraints (e.g., `emit_c` and `emit_ir` are mutually
  exclusive).

**Migrator options.** Specify whether `MigrateOptions` is a separate
struct attached via `Workspace.set_migrate_options` (v2 design) or
folded into `BuildOptions` as an optional field. Justify the choice.

**CLI parser refactor plan.** The current parser mutates Compilation
state directly. The target is: parser produces a `BuildOptions` value,
driver constructs a workspace from it. Specify:
- Where the parser lives after refactor.
- How defaults are computed.
- How validation errors are surfaced.
- What the parser's return type is.

**Compatibility plan.** Existing build scripts use specific CLI flags.
After D2, those flags still work. Specify the test fixture set that
validates byte-for-byte CLI compatibility through the refactor.

### Done criteria

- Every current CLI flag mapped to a BuildOptions field.
- BuildOptions struct shape finalized.
- CLI refactor plan covers parser, defaults, validation, output.
- Compatibility test fixtures enumerated.

## 8. P6: Build Script Compatibility Survey

Inventory every current use of build.w, action functions, and capability
APIs across the repository. Produce `docs/audits/build-script-survey.md`.

### Files to survey

- `build.w` (top-level)
- `build_compiler.w`
- `build_emit_c.w`
- `build_pcre2.w`
- `build_runtime.w`
- `build_seed.w`
- `build_selfhost.w`
- Any other `build_*.w` files

### Required inventory

For each file:
- Functions defined (with signatures).
- Capability methods called (BuildCtx.*, ActionCtx.*, ToolFs.*,
  ProcessRunner.*, etc.).
- External processes spawned (with arguments).
- Files read or written (with paths).
- Build graph targets contributed (with kinds).

### Compatibility planning

For each capability method or external process call:
- Will it continue to work unchanged through D1? (D1 only changes the
  dispatch mechanism, not the semantics.)
- Will D7 (migrate actions) replace it with a Workspace call?
- If yes, sketch the replacement.

### Done criteria

- Complete inventory across all build files.
- Each capability method use classified.
- D7 migration targets identified with sketched replacements.
- Any unsupported pattern in the v3 design flagged as a blocker.

## 9. P7: Behavior Regression Tests

Lock in current build.w and action runner semantics with behavior tests
that will catch regressions during D1. Tests land before D1 starts.

### Tests required

**`test/behavior/behav_build_w_basic_invocation.w`**: a minimal build.w
fixture that exercises BuildCtx.diagnostics(), Target construction, and
Build return. The driver invokes this and the test asserts the build
graph shape matches expectations.

**`test/behavior/behav_action_capability_filesystem.w`**: an action
fixture that uses ToolFs to read, write, and probe paths. Asserts
results match expected behavior under the current generated-runner
model. After D1, the same test must pass with the in-process evaluator.

**`test/behavior/behav_action_capability_process.w`**: an action
fixture that uses ProcessRunner with capture and timeout. Asserts
captured stdout/stderr/rc match expectations.

**`test/behavior/behav_capability_token_mismatch.w`**: a test that
constructs a capability with a wrong token (via test-only driver entry)
and confirms the call aborts with a structured tool-capability-violation
error rather than silently succeeding or producing undefined behavior.

**`test/behavior/behav_action_crash_diagnostic.w`**: an action fixture
that intentionally panics. Asserts the driver produces a diagnostic
including target name and source location.

**`test/behavior/behav_action_no_deps_isolation.w`**: an action target
invoked via `--no-deps`. Asserts that only the target's declared
inputs/outputs are touched.

### Done criteria

- All six tests committed.
- Each test passes against current main with the existing generated-runner
  model.
- Each test has a clear pass/fail predicate (no flaky timing assertions,
  no assertions on transient diagnostic text).
- Tests are added to `make test` / `with build :test`.

## 10. P8: Pre-D1 Refactor of src/main.w

The current action-runner generation code in `src/main.w` is a single
large block that mixes runner generation, environment setup, subprocess
execution, output capture, and cleanup. D1 will replace this block.

Pre-D1, refactor `src/main.w` to isolate the action-runner code into
its own function or function group, so D1's diff is a clean
replacement of a few well-defined functions rather than a sprawling
multi-section change.

### Refactor scope

Extract from the current `run_build_action_from_build_w` and surrounding
code:
- `generate_action_runner_source(target, ...)` — produces the
  `__with_build_action_runner.*.w` content. Returns a string.
- `compile_action_runner(source, ...)` — compiles the runner source to
  a binary. Returns the binary path.
- `execute_action_runner(binary, target, ...)` — sets env vars, invokes
  the binary, captures output, replays diagnostics. Returns rc.
- `cleanup_action_runner(binary, ...)` — removes the binary and
  intermediate files.

These four functions become the cut point. D1 replaces them with
in-process evaluator dispatch.

### Constraints

- No behavior change. Tests from P7 must continue to pass byte-for-byte
  after the refactor.
- The refactor lands as its own commit, separate from D1.
- Function names and signatures designed to make the D1 replacement
  obvious (e.g., `execute_action_runner` becomes
  `evaluate_action_capability_call` in D1).

### Done criteria

- Refactor committed.
- All P7 tests pass.
- `with build :build`, `with build :fixpoint`, `with build :test` pass.
- The diff for D1 will replace these four functions, not interleave with
  surrounding driver code.

## 11. P9: Verification Baseline

Record the verification baseline for Phase D in
`docs/audits/pre-d1-baseline.md`.

### Required content

- Commit hash at the start of D1.
- Output of `with build :build` — successful build artifacts list.
- Output of `with build :fixpoint` — FIXPOINT confirmation.
- Output of `with build :test` — full test count and pass status.
- Output of `with build :emit-c-test` — EMIT-C OK confirmation.
- Behavior test count (should reflect the new P7 tests).
- Selfhost test count.
- Build artifact sizes (out/bin/with size; runtime object sizes).

This baseline is the "before" snapshot. D1 and subsequent slices must
demonstrate either parity with this baseline or explicitly account for
deviation.

### Done criteria

- Baseline committed.
- Baseline is reproducible from the recorded commit hash on a clean
  checkout.

## 12. Sequencing

Pre-D work can partially parallelize. Suggested order:

**Wave 1 (independent, can run in any order):**
- P2: ComptimeEval audit
- P3: Parallel state audit
- P6: Build script compatibility survey
- P7: Behavior regression tests

**Wave 2 (depends on Wave 1 findings):**
- P4: Capability dispatch design (depends on P2)
- P5: BuildOptions concrete design (depends on P6 inventory)
- P8: Pre-D1 refactor of src/main.w (depends on P7 tests existing)

**Wave 3 (depends on Wave 2):**
- P1: Design doc v3 (depends on P2, P3, P4, P5)

**Wave 4 (final):**
- P9: Verification baseline (depends on P7, P8 being committed)

### Estimated effort

- P2: 1 session (audit + write-up)
- P3: 1 session (audit + write-up)
- P6: 1 session (inventory + write-up)
- P7: 1-2 sessions (test design + implementation + verification)
- P4: 1 session (design only)
- P5: 1 session (design only)
- P8: 1 session (refactor + verification)
- P1: 1 session (revision)
- P9: < 1 session (baseline capture)

Total: roughly 8-10 sessions of pre-D work. This is real investment.
The alternative — discovering design issues during D1 implementation —
costs more.

## 13. Done Criteria for Pre-D Completion

All of the following must be true before D1 implementation begins:

- All deliverables in §2 exist and are committed.
- `docs/completed/phase-d-design.md` v3 has passed re-review.
- All P7 tests pass against the P8 refactor.
- The P9 baseline is captured.
- No open questions remain in the design doc (no "TBD" or "to be
  determined" markers; no audit gaps).
- The slicing in §13 of the design doc (D1-D8) has explicit scope,
  deliverables, and verification for each slice.

When this list is checked off, D1 begins. Not before.

## 14. What This Document Is Not

This document does not specify Phase D itself. The design contract for
Phase D lives in `docs/completed/phase-d-design.md`. This document is the
preparation contract — the work that must complete before that design
can be implemented confidently.

This document also does not bind future phases (E and beyond). It is
scoped to the work needed to begin Phase D.
