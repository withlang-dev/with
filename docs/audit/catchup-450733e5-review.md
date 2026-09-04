# Catch-up source review — `31f77937` → `450733e5` (78 commits)

Method: **read-only**. No builds, probes, or test runs beyond the draws
already recorded in `modules/src__BuildGraphRuntime.w.md`. All claims below
come from `git log`, `git diff`, and reading the changed sources at the new
revision. Commit subjects are quoted for traceability.

## Delta map

| Theme | Commits (subjects condensed) |
|---|---|
| `.wo` bundles + D39 interfaces (batches C0–C3) | `.wi` flavor, emitter, fingerprint, harness, generic-omission, pcre2 bundle root + migrate action, bootstrap chain link, wo-drift lane, regex-shim compile |
| ABI Level 0 | rules into `src/FnAbi.w`, hash recorded + battery-checked |
| #921 build runner | native Action workers, pooled test lanes, RSS tripwire/instrumentation, try_wait/maxrss wrappers |
| Sema/MIR correctness | effect-edge rule (#927), use-after-kill operand decode (#927, #742), generic-inst reflection (#742), frozen-cache field projection (#742), enum payload checks (#933), comprehension borrows (#934), iter binding (#925), borrow-tail bookkeeping |
| Diagnostics/parser | named unresolved imports (#932, #930), `c"..."` escapes + unknown-escape errors (#929) |
| Rulings/docs | D34–D39, sourcing plan, wo_bundles, With ABI v1, harden plans, perf baselines, fiber #369, LF pinning (#942), -O1 IR path |

## Completed modules: 6 untouched, 5 touched

Byte-identical: `AnalysisTypes`, `BuildGraphDispatch`, `BuildGraphKinds`,
`BuildGraphOps`, `Overflow`, `Span`. Their evidence stands unmodified.

| Module | Delta | Effect on evidence |
|---|---|---|
| `BuildGraphCache` | one word: `build_cache_graph_path` private → `pub` (line 771) | none semantic; evidence stands, addendum noted here |
| `BuildGraphMaterialize` | one added call: `build_graph_complete_edges(move graph)` (line 279) | D36 inference now enforced in the pipeline; evidence stands, behavior extended |
| `BuildGraphModel` | +51 lines: `build_graph_output_index` + `build_graph_complete_edges` | new logic inside a completed module; needs an evidence addendum (see R-1) |
| `TargetSpec` | `target_spec_name()` split; new `target_spec_resolved_name()` | audited function changed shape; needs an evidence addendum (see R-2) |
| `BuildGraphRuntime` | +14 lines, 4 wrappers | re-audited in-module this session; complete at new rev |

## Retained finding anchors

- `rt/rt_core.w` has exactly **one** hunk in the delta (bulk byte-append,
  ~line 2511). The entire filesystem section is byte-identical: BGO-002's
  read-conflation branch, BGO-011's `with_getenv_str` leak branch, and
  BGR-001's short-write branch all hold (line numbers +20 only).
- `BuildGraphOps.w` is byte-identical: BGO-001 through BGO-011 stand as
  written.
- BGO-003's cited field constructors moved with identical semantics
  (`Target.timeout`/`working_dir`/`with_env` now `lib/std/build.w:2000-2013`,
  `extra_output` at :2401). The Ops-layer omission is unchanged (Ops file
  identical), so the finding stands; only the citation needs the new lines.
- `build_graph_audit_edges` + `build_graph_edge_find` were **removed** from
  `BuildGraphSupport.w` (D36 replaces audit-notes with enforced inference).
  Any evidence or issue text citing the audit-note behavior should point at
  `build_graph_complete_edges` in `BuildGraphModel.w` instead. The old
  warning — ordering-only edges must not feed dep_rebuilt — is now a design
  property to re-verify, not a code comment (see R-1).

## New modules reviewed

All ten were read (small files fully; `build/wo.w` fully at 563 lines;
`BundleInterfaceEmit.w` header, refusal inventory, and entry points of 1058
lines — line-by-line verification of the emitter belongs to target-17/23
work, stated as a gap, not a verdict).

- `src/FnAbi.w` (134): the D6 single classifier. Clean rule centralization
  with one structural caveat (R-3, now traced read-only): the single
  adapter is `Codegen.arg_pass_mode` (`Codegen.w:4719-4724`), fed by
  Sema-finalized `sig_param_uses_value_ref_abi` and one LLVM-type
  derivation with void→i32 fallback — same sources for prologue (line
  4749) and the documented call-site read (line 4773). Residual
  (target 3): enumerate every call-lowering path and prove each reads
  `arg_pass_mode` or a provably-identical twin — the direct
  `internal_abi_needs_indirect_param` call sites (`Codegen.w:4559`,
  `:4571`, `:5052`, `:5061`, `:5373`, `:5974`; `CodegenDispatch.w:462`,
  `:510`, `:2818`, `:15259`, `:17203`, `:18069`) are the starting
  checklist, since any of them deciding argument shape independently
  reintroduces the per-path divergence class.
- `src/compiler/AbiStamp.w` (19): post-link slot patching with an
  `is_stamped` guard. The guard is advisory — every bundle-key computation
  must call it; that call-site audit is target-18 work.
- `src/compiler/BundleFingerprint.w` (61): deterministic by construction
  (bytewise sort, no ids/spans, target-qualified header). Trust rests on the
  emitter's row contents, which the two-pass equality check enforces.
- `src/compiler/BundleInterfaces.w` (104): global registry consulted before
  embedded stdlib — shadowing by design. Duplicate `module <path>` sections
  overwrite silently in the map insert (line 79); no duplicate diagnostic
  was found at this layer (R-4, minor).
- `src/compiler/EmbeddedBundles.w` (109): unsafe blob views with an
  empty-slot guard; manifest prefix/path parsing is two copies of one loop
  (target-24 note); no `\r` trim though `.wi` registration trims `\r`
  (CRLF inconsistency, minor); presence = manifest-nonempty, object
  unchecked (R-5, edge).
- `src/compiler/ModuleSource.w` (29): the single lookup in the documented
  order. Sentinel collision (R-6): `bundle_interface_text` returns `""` for
  both absent and empty sections, so a legitimately empty bundle interface
  falls through to the embedded source — a silent semantic difference.
- `build/abi.w` (61): fail-closed battery gate (missing/malformed/empty
  record all error; mismatch names files). No bypass found.
- `build/wo.w` (563): fail-closed throughout — slot coherence (corpus, target,
  ABI, interface, object hashes), stamp verification refusing unstamped
  compilers, manifest cross-checks, manifest-last publish order, drift lane
  with dual-harness fallback. Three observations (R-7): slot→out `.o` copies
  go through text read/write (binary-transparency unproven, Windows angle);
  empty-HOME store falls back to `/.local/with-wo`, the BGO-008 shape but
  landing loud; drift object comparison shares the text-path question.
- `lib/std/re/bundle.w` (35): generated root; `pcre2test`/`pcre2posix`
  excluded as harness per the header comment. No issue.
- `src/compiler/BundleInterfaceEmit.w` (skim): refusal inventory is broad
  (anonymous/error/range/trait-object types, non-folding consts, droppable
  mutable globals, extension methods, async/gen/comptime) — the
  no-silent-fallback rule holds structurally. Full verification deferred
  to target-17/23 work.

## Spec and ruling deltas

New decisions D34 (string-builder `++`), D35 (`.=`/`..=`), D36 (inferred
producer edges), D37 (migrate-whole sourcing), D38 (versioned With ABI
boundary), D39 (bundle interfaces, Eric's verbatim ruling). Spec gains the
D39 projection (§3.4 cross-boundary origin rule; §18.5c) and
`version --abi-sha`. All normative text is blessed-wording per commit
subjects; no agent-drafted spec text was found in the delta.

Audit impact: §18.5c creates a new surface for targets 6 (provenance across
the `.wi` boundary), 10/18 (bundle identity and selection), 22 (the new
normative rules need positive/negative/edge tests), and 24 (the D6
input-provenance question above). The `.wi` boundary rules as written are
internally consistent (no body-inferred facts cross; multi-origin
declarations are rejected, not approximated).

## Semantic fix commits (characterized, not deep-reviewed)

Effect-edge transfer (#927), use-after-kill operand decode (#927/#742),
generic-inst reflection + frozen projection (#742), enum payload call
semantics (#933), comprehension borrows (#934), iter binding (#925),
borrow-tail bookkeeping, escape validation (#929), named-import diagnostics
(#932/#930), fiber overflow diagnostic (#369), `-O1` IR path, LF pinning.
Each is small and well-scoped by subject; whether each fix is complete and
covered belongs to its owning target's matrix, not to this delta review.

## Numbered review notes for target work

- R-1 (Model evidence addendum): `build_graph_complete_edges` infers dep
  edges for every consumed-produced file match. Confirm the over-inference
  direction: a consumer whose use is order-only now gains a dep edge and
  feeds dep_rebuilt — perf-only if true, correctness if some consumption
  was load-bearing without bytes. Re-verify the removed audit-note's trap.
- R-2 (TargetSpec evidence addendum): `target_spec_name` vs
  `target_spec_resolved_name` split; re-check every caller of the old
  spelling for which semantic it needed.
- R-3 (target 3): audit the Codegen adapters feeding
  `fn_abi_pass_mode`/`fn_abi_platform_aggregate_indirect` for input
  provenance — one producer per input, or D6's bug class survives.
- R-4 (minor): duplicate `module <path>` sections in one `.wi`
  (`BundleInterfaces.w:79` map insert).
- R-5 (edge): bundle presence ignores object-blob emptiness
  (`EmbeddedBundles.w:44-45`).
- R-6 (edge): empty interface section falls through to embedded source
  (`ModuleSource.w:20-23` vs `BundleInterfaces.w:63-67`).
- R-7 (target 18/19): binary transparency of ToolFs text paths for `.o`
  copies and drift comparison (`build/wo.w:361-365`, :471); empty-HOME
  store path (:104-108).
- R-8 (target 3/13): `codegen_canonical_module_path` (`FnAbi.w:75-92`)
  depends on PWD for relative non-std paths and never realpaths symlinks —
  same module via different spellings hashes to different bundle symbols.

## BuildGraph family source review (read-only; modules NOT marked complete)

`BuildGraphSupport.w` (341 lines), `BuildGraphTools.w` (86), and
`BuildGraphTests.w` (208) were read in full at the new revision. No
execution: these are review notes for target work, not completion evidence.

- S-1 (validators): `generated_path_valid`, `manifest_relative_path_valid`,
  and `path_project_contained` (`BuildGraphSupport.w:107-161`) block `..`
  but not `.`, and `path_project_contained("")` returns true. The `.`
  spelling passes every path validator — the same hole shape as BGO-001's
  clean predicate, at three layers. Manifest entry `.` then flows into the
  BGO-002 read conflation. Candidate finding when execution resumes.
- S-2: the three `*_output_path` helpers return `""` for multi-target
  explicit outputs (lines 10-36, same shape thrice — target-24 note).
  Callers receiving `""` need a check each.
- S-3 (target 21): `collect_test_files` (lines 279-289) cannot distinguish a
  missing test dir from an empty one (`list_files` → `""` either way, the
  BGO-002 echo) — a typo'd test directory runs zero tests and reports
  green. Harness-honesty gap.
- S-4: `build_graph_times_report` ignores its mkdir/write return codes
  (lines 323-324) — silent telemetry loss. Minor.
- S-5: `build_graph_validate_process_args` (lines 211-226) screens
  entry/output/inputs/args for NUL but not extra_outputs, cwd, or env
  pairs — BGO-003-adjacent gap at the validation layer.
- S-6: `build_graph_str_compare` duplicates `with_str_cmp_ref` byte
  ordering (target-24 note; harmless while both stay bytewise).
- T-1: env-provided tool paths are used verbatim with no
  existence/executability check (`BuildGraphTools.w:17-28`) — late
  confusing failure instead of an early diagnostic. Minor.
- T-2 (sharp): `build_graph_llvm_prefix` (`BuildGraphTools.w:51-65`) has no
  linux_aarch64 row though the tree ships that backend, so a Linux ARM64
  host falls through to the `/usr/local/llvm` system prefix — the exact
  trust-a-system-LLVM shape the project rules forbid, failing silently
  instead of loudly. Candidate finding when execution resumes (check what
  consumes the fallback). Verified `.deps/llvm-22.1.6-linux-x86_64` matches
  the table on this host; the Darwin spelling is unverified here.
- E-1 (target 21): the PASS-verdict cache
  (`BuildGraphTests.w:134-200`) banks greens keyed on (compiler, file,
  target config) and skips reruns. Cross-checked read-only against
  `build_cache_test_verdict_key` (`BuildGraphCache.w:461-465`) and the
  target sig (`:438-449`): covered are compiler content (unstamped-sibling
  aware), test content+relative path, opt/args/defines/includes/libs, and
  one env var (`WITH_MEMORY_LIMIT_BYTES`). Residual gaps: sibling/helper
  file contents are unhashed (sharpest — contrast #686's action-source
  closure), the timeout field is keyed nowhere (currently unconsumed for
  tests, so latent), other env vars are absent, and the `v1` store tag is
  write-only (never checked on load). Store-parse and cache-write failures
  both fail safe (skip/rerun). Failures always re-run, which is the right
  half of the design.
- E-2: `build_graph_test_parse_jobs` (lines 59-66) uses unchecked
  accumulation, but garbage folds to the core-count default (fail-safe
  direction) — the BGO-009 contrast case: unchecked arithmetic matters
  where values flow into modes, not here.
- E-3: same-basename capture collision is prevented by construction
  (`test_target_files` filters candidates to one directory, lines 28-36),
  so the parallel window's shared `basename.stdout` paths cannot alias.
  Invariant worth a regression test, not a finding.

## Sema/MIR fix commits (read-only deep read)

Each fix below ships with its regression test and an explanatory commit
message (all Eric-authored); the review adds residuals, not re-verdicts.
No execution was performed — author-reported test outcomes are quoted as
reported, not verified.

- #742 cluster (b9d81495 + 307ac4c7): the compute-on-miss fallback is gone;
  eager sweep re-registers pending insts until fixpoint, and codegen reads
  frozen caches only. Termination holds: the sweep sets progress only on
  pending insts, and re-registration inserts exactly the key pendingness
  checks (`(tid,0)` for structs). Residuals: (a) the enum side's fill
  guarantee was not traced with the same care — confirm
  `preregister_generic_enum_payloads` inserts the starts key it checks;
  (b) an enum whose first variant symbol is 0 never counts as pending and
  never fills — presumably vacuous, unproven.
- be015f47 (#927 validator): `mir_rvalue_read_locals` decodes reads per
  kind with the MIR printer as the stated layout contract, replacing a
  d0-for-all read plus an aggregate special case — strictly better, with a
  rebind-builder fixture pinned at `violations=0`. All current kinds
  verified covered (USE/CAST/ARRAY_FILL→d0 operand; BINOP→d1,d2;
  UNOP→d1; DISCRIMINANT/LEN→d0 place; SLICE→place+operands; AGGREGATE→
  field operands; STR_CONCAT_N→arg range; REF/ADDR_OF→none). Residual
  (target 1), sharpened read-only: the printer renders unknown kinds
  LOUD (`rvalue<k>(d0,d1,d2)`, `Mir.w:1371`) while the decoder yields
  zero reads SILENTLY — add explicit empty arms for REF/ADDR_OF (if
  borrow-creation is truly not a read; otherwise that is its own hole)
  plus a loud catch-all for unknown kinds. Validator-trustworthiness
  work should feed an uncovered kind and prove rejection.
- 75cfc037 (#927 effects): one `effect_edge_transfer` rule read by both
  fixpoint and audit — the one-rule-one-home pattern done right, including
  the pre-freeze/frozen Copy-ness split. Residual (target 24): the
  unification is complete only if `is_copy` and `is_copy_frozen` agree on
  every input; prove it or the divergence moved, not vanished.
- 784b429e (#933): variant payloads lower through the call-arg adjustment
  chain with a fail-loud hole for typeless results, plus arg checking
  mirrored from bare calls. Residual (target 2/13): diff the payload chain
  (ref → copy-ref → deref → plain) against `lower_call_arg`'s full
  sequence — any extra step there is a live divergence.
- 891fd019 (#934) + c636b8d2 (#925): comprehension and `for` agree on
  place-receiver reads and Drop-view vs Copy-value dispatch, with Sema
  typing `vec.iter()` bindings to match. Residual (target 24): Sema's
  predicate textually mirrors MirLower's (`"iter"` on a Vec-instantiation
  receiver) — two spellings of one dispatch rule that must change together.
- 1c50ae46: borrow-proven tails cancel move bookkeeping across four
  structures (field places/types, locals, moved-fields, local-moved).
  Residual (target 4/5): completeness is asserted, not enumerated — a
  fifth move record anywhere (drop flags, region entries) reopens the
  caller-struct blanking this fixed. Code-search the full set.
- 441dfc62 (#930/#932): imported-module diagnostics misattributed because
  Resolve and the frontend numbered files from 1 independently; fixed at
  the call site with a fixture asserting `helper.w:2` and no
  `<embedded-std>`. Residual (target 8/10): the two id-spaces still exist —
  audit every other consumer that pairs a file id with a text before
  calling this closed.
- 8034b3d8 + 3858834b (#929): unknown escapes are compile errors in
  strings and c-strings, with behavior + error tests. No residual noted
  at this depth.

## #921 runner, optimizer, and leftover commits (read-only)

- 3aba5554 (phase 1): Action workers exec a natively compiled build.w;
  Workspace-surface calls exit 97 (reserved: driver re-runs through the
  evaluator, never a failure) with a `runner-fallback.list` so retries
  happen once. Native effect records mirror the evaluator's format, with
  the comment itself flagging parity as load-bearing. Residuals
  (target 24/21): assert byte-parity between the two emitters with a test,
  and audit every interpreter of exit 97 — a user action genuinely
  exiting 97 would take a needless evaluator lap today.
- 88832131 (parity): capability checks loosened to reject only
  never-mintable tokens, with the mint gate as the single env-matching
  point; `WITH_BUILD_TOOLFS_SUPPRESS` scopes graph evaluation only.
  Verified read-only: the runner entry sets it around `build(...)` and
  clears before `__driver_run_action` (`src/main.w:1383-1385`), so action
  writes are not suppressed. Residual: the security boundary now rests on
  the mintability predicate — a dedicated capability-trust pass should
  review it, not this delta.
- c4c2a403 + a4b61c6f + 6cd878d3: pooled-worker RSS stamped at true child
  exit (the maxrss natives audited in-module), Test-kind workers admitted
  to the graph cache, native Workspace for plain compiles. Residual: the
  runner-binary cache key (`build_cache_graph_key`) must cover every
  runner-relevant input or a stale runner serves a changed build.w —
  cross-check when execution resumes.
- ca0a94a0 + fb71b606: the IR→object path now runs the single
  `wl_optimize` pass-runner — consolidation done right, but it preserves
  a pre-existing silent-swallow: `wl_optimize`
  (`src/compiler/LlvmBridge.w:1223-1234`) fetches the LLVM error message
  and disposes it without surfacing, returning Unit. No regression, but
  target-23 now has exactly one choke point to fix.
- 441dfc62 covered above. 23fdc071 (fiber #369) un-skips a diagnostic
  test; 6daa73f0 pins LF line endings process-wide; D34/overflow trio
  (70898d0c, 646dab5f, 0ce5b23c, e5e19578, d62409ca) and reseed gates
  (fefc78df, f481eb58) characterized from subjects and small diffs only —
  no residuals noted at this depth. Docs-only commits (D-docs, sourcing,
  perf baselines, harden plans, AGENTS prose) carry no code impact.

## Link/Compilation bundle integration (read-only)

- `Link.w` (+157): on-demand bundle selection with abi/target/interface
  checks and atomic blob extraction (temp + pid/nanos rename, lost-race
  re-read tolerance). Residuals (target 18/23/24): (a) the manifest-field
  parser is now the THIRD copy of one shape (`Link.w` newcomer,
  `build/wo.w:wo_manifest_field`, `EmbeddedBundles.w` prefix/path pair);
  (b) `link_stage_bundle_needed` uses substring containment, not
  prefix-anchoring — a user symbol merely containing a bundle prefix
  selects the bundle (likely harmless, unproven);
  (c) `link_stage_extract_blob` compares file reads by content through
  the BGO-002/BGR-001 natives — the conflation echoes in new code
  (directory reads `""`; write rc ignored in favor of re-read, which is
  the safer half); (d) `<probe-failed>` fails closed toward inclusion,
  the right direction.
- `Compilation.w` (+325): bundle options plumbed with a `loaded` once-flag
  mirrored into `Zcu.bundle_corpus`. Residual (target 18): prove the
  once-load gate holds under option mutation (set-then-set with different
  prefixes after a load).

## What this review did not do

No execution of any kind: no builds, probes, allocator runs, or test
suites. New-module verdicts above are source-review findings at the stated
depth, not target completions. The emitter's 1000-line body, the Sema/MIR
fix commits, and the R-notes' resolutions are queued for their owning
targets. The 10 new compilation units still await checklist inventory
(noted, not performed).
