# Audit 006 — type identity, generic specialization, and comptime equivalence

Status: **bounded source audit complete; no implementation module is complete**  
Targets: overview 8, 9, and 12  
Scope authority: tracked production source at
`31f77937abad3bc6573df3b71a0c99b605d6ea8e`, plus explicitly identified local
executable behavior  
Edits: this report only; no compiler, runtime, test, specification, or issue
changes

## Executive verdict

Direct textual producer search and current-source-bound stage1 behavior do not
yet yield one explainable semantic-state path.

The source declares `typed_expr_types`, the concrete-specialization descriptor
family, and a generic specialization cache. Direct search located only comptime
transformation/evaluation writes to `typed_expr_types` and did not locate
ordinary type-checker or concrete-specialization descriptor writes. The
current stage1 nevertheless reports 1,929 typed-expression facts and two
concrete specialization rows for one fixture.

Audit 009 materially narrows that observation: the stage1 cache ledger binds
the executable to the current declared input contents and recorded seed, and
`build --explain stage1 :stage1` reports it fresh. The unstamped version string
is a designed sentinel, not missing provenance. Therefore the direct-write
search was not a sound proof that producers are absent; indirect mutation,
aliasing, generated paths, compiler semantic effects, or a defect remain
possible. This is an unresolved producer-discovery/semantic-authority
contradiction, not a confirmed source/artifact integrity defect.

This pass does **not** claim that ordinary generic execution is currently
broken. The bounded executable controls passed. It claims that the producer
path was not located and that semantic completeness cannot currently be proven
by the direct search or the existing validators.

The live validator also has a source-proven false-confidence seam: missing
expression sidecars are skipped, and empty specialization tables pass the phase
audit vacuously. Comptime has useful differential tests, but its independent
allowlisted evaluator remains a second semantic implementation and the six-file
differential corpus does not cover ownership, errors, generic specialization,
reflection, or most control-flow composition.

## Revision and evidence provenance

- Audit snapshot: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`.
- `3305b68119b0502009c2079d79ea8c531694e619` is its first-parent source
  ancestor for the audited compiler files.
- `git diff --stat 3305b681..HEAD -- src/Sema.w src/ComptimeEval.w
  src/Mir.w src/MirLower.w src/ComptimeTransform.w src/Analysis.w` emitted no
  differences.
- `out/bootstrap/bin/with-stage1 version` prints
  `WITHVERSIONSTAMPv1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`. Audit 009 establishes
  that build stages are intentionally unstamped and only the final release
  binary is patched; this sentinel is not evidence of unknown provenance.
- The current stage1 cache ledger and hashed `seed-input.json` bind stage1 to
  the present declared compiler/runtime/stdlib inputs and recorded seed.
  Read-only `out/bootstrap/bin/with-stage1 build --explain stage1 :stage1`
  reports `fresh`; the stage1 SHA-256 is
  `d1f65fd87a450c24a00bf2498a9bc10f9cf55a42cb199c5d8ef667a2bb4cab1a`.
- That repository-internal ledger is not an independent reproducible-build or
  fixpoint attestation, but it refutes stale/unattributed stage1 as the
  supported explanation for the producer-search observation.
- The codebase-memory graph was ready but does not index With (`.w`) bodies
  sufficiently for these targets. Discovery fell back to Tilth full-content
  search and exact source slices, as permitted when graph evidence is
  insufficient.
- No full compiler build or fixpoint was run. Audit 009's read-only freshness
  evidence is the strongest current source/artifact binding available without
  those broader checks.

## Source authority map

### Type identity and sidecars

- `src/Sema.w:959-1005` — expression/binding sidecars, generic substitution
  environment, generic caches, and concrete-specialization descriptor fields.
- `src/Sema.w:3614-3666` — real generic type-instance identity cache,
  collision validation, table scan, and instance creation.
- `src/Sema.w:1499-1531` — comptime Sema copy preparation and cache rebuilds.
- `src/Analysis.w:316-328` — typed-expression fact collection.
- `src/Analysis.w:436-469` — AST facts annotate a missing entry as
  `<untyped>` but do not reject it.
- `src/CCodegen.w:1083-1095` — missing global value type falls back to `i32`.
- `src/Codegen.w:2962-2976` — LLVM codegen consults the sidecar, then uses
  other inference/fallback paths.
- `src/ComptimeEval.w:2598-2608` — comptime method results use a node type or a
  caller-supplied fallback.

### Generic specialization

- `src/Sema.w:982-1005` — generic substitution, descriptor, and cache storage.
- `src/Mir.w:468-477` — MIR's explicit statement that AST call nodes are
  shared by all specializations and Sema sidecars are overwritten; MIR stores
  per-specialization signature/mono-symbol contracts.
- `src/Analysis.w:566-590` — specialization facts are collected solely from
  the descriptor arrays.
- `src/Analysis.w:1251-1285` — phase audit checks rows that exist, but does not
  require a row for each generic MIR body/call.
- `src/ComptimeEval.w:3397-3432` — generic comptime method evaluation requires
  a concrete signature and descriptor substitution row.
- `src/Codegen.w:5944-5949` — codegen optionally consumes the descriptor to
  recover the function declaration for noalias attributes.

### Comptime

- `src/ComptimeEval.w` — independent value representation and evaluator.
- `src/ComptimeTransform.w` — compile-time AST rewriting and selected sidecar
  writes.
- `docs/with-specification.md:9969-10081,10244-10259` — type introspection,
  comptime cascade, generated-code checking, effects, and determinism contract.
- `build.w:2241-2245,2405` — six-file `test/comptime_diff/*.w` target wired
  into the test aggregate.

## Finding 1 — unresolved producer-discovery and semantic-authority contradiction

Classification: **High audit blocker / candidate semantic-authority defect**,
not a confirmed user-program miscompile or provenance defect  
Severity: **High assurance gap**  
Confidence: **High** for the observed search/behavior mismatch; **Low** for its
unlocated cause

### Exact evidence

Full-tree source search found 39 references to `typed_expr_types`. Direct writes
exist only in:

- `src/ComptimeEval.w:3472,3558,7961,7965`;
- `src/ComptimeTransform.w:1103,1106,2988,2991`.

No direct general Sema type-checker producer was located. This direct-search
result is insufficient to prove absence: Audit 009 binds stage1 to the current
declared inputs, and that stage1 demonstrably populates the table. The producer
may be indirect, aliased, generated, or expressed through a compiler semantic
effect that a field-name search does not reveal.

Likewise, `generic_specialization_cache` is declared and initialized at
`src/Sema.w:985,1835,2185` but has no read or write. The
`concrete_specialization_*` family is declared/initialized and consumed by
Analysis, ComptimeEval, Codegen, and receiver lookup, but direct source search
did not locate its producer write. The same limitation applies: this is a
producer-discovery result, not proof that the live producer is absent.

The executable supplies the counter-evidence that prevents treating the direct
search as an absence proof:

```text
with-stage1 analyze ...behav_d21_comptime_generic_pipeline_return.w \
  summary:kind=expression
=> facts 1929

with-stage1 analyze ...behav_d21_comptime_generic_pipeline_return.w \
  select:kind=specialization
=> 2 rows:
   ComptimeGenericMut.produce__receiver__107_14 T=ty14, Self=ty107
   ComptimeGenericMut.produce__receiver__107_13 T=ty13, Self=ty107
```

The audited source files are unchanged from `3305b681`. Audit 009's ledger and
effect evidence attributes stage1 to the current declared input contents and
recorded seed. The designed version sentinel does not weaken that attribution.
The remaining unanswered question is which mutation/production path populates
the facts; this audit did not locate it and does not guess.

### Blast radius

- Every expression consumer of `typed_expr_types`: MIR lowering, LLVM and C
  codegen, trait-generated bodies, comptime, LSP hover/type-at-offset, typed
  dumps, and analysis.
- Every user-defined generic specialization: body identity, substitution,
  receiver mode, ownership/drop classification, ABI selection, comptime method
  execution, and noalias metadata.
- Semantic assurance: until the producer path is traced, reviewers cannot
  establish that every required fact is produced exactly once from the intended
  authority, even though the current-ledger-bound stage1 produces facts for the
  bounded fixture.

### Five Whys

1. Why does direct source inspection not explain the observed semantic facts?
   No ordinary direct writes were located by the field-name search.
2. Why is that not proof that writes are absent? Current-source-bound stage1
   emits the facts, so an indirect mutation, alias, generated path, compiler
   semantic effect, or defect remains possible.
3. Why was the indirect path not identified? The semantic state has no audited
   single producer API or mutation trace that joins each fact to its authority.
4. Why do semantic audits not resolve the question? Their collectors/auditors
   iterate only rows already present and do not prove producer completeness.
5. Why does this matter? Type and specialization facts control MIR, ownership,
   ABI, comptime, and codegen, so unexplained authority prevents a defensible
   completeness claim even when bounded behavior passes.

### Proper repair boundary

First trace the live producer path; provenance is sufficiently reconciled for
that investigation, although an independent rebuild/fixpoint remains stronger
future evidence.

1. Trace every mutation of `typed_expr_types` and the concrete-specialization
   descriptor family in the current stage1 path, including aliases, raw-place
   writes, generated sources, and whole-`Sema` synchronization.
2. Join each emitted fact to the exact producer function, branch, node, and
   specialization key. If any required fact has no valid producer, root-cause
   that gap at the Sema expression-check or specialization-registration
   boundary.
3. Make typed expression results and specialization descriptors obligatory
   phase outputs, not optional mutable maps inferred later by consumers.
4. Remove the unused `generic_specialization_cache` or make one documented
   specialization registry the sole authority; do not add another cache.
5. Prohibit silent type fallbacks once Sema has succeeded. A missing semantic
   fact at MIR/codegen must be a diagnostic/non-zero failure.

No exact semantic code patch is recommended until step 1 identifies the live
producer and its authority.

## Finding 2 — high: completeness audits are vacuous over missing facts

Classification: **confirmed unreported validator gap**  
Severity: **High**  
Confidence: **High**

### Exact root cause

- `analysis_collect_expressions` at `src/Analysis.w:316-320` executes
  `if not sema.typed_expr_types.contains(node): continue`.
- `analysis_collect_ast_node_tree` at `src/Analysis.w:444-467` renders the
  missing type as `<untyped>` without a violation.
- `analysis_audit_phase` at `src/Analysis.w:1278-1284` validates only
  `0..concrete_specialization_syms.len()`. Zero rows therefore pass even if MIR
  contains concrete generic bodies or required generic call contracts.
- `analysis_audit_storage` checks parallel resolved-argument tables and key
  arithmetic, not expression-sidecar coverage.

The negative control is the same D21 fixture: `audit:phase` and `audit:all`
both exit 0, while direct search did not locate the live producers for the
tables they are auditing. `audit:all` reported `calls=0` for resolved argument storage while its
MIR fact stream contained concrete generic calls; those are different tables,
but the summary can create false confidence unless completeness joins them.

### Five Whys

1. Missing expression/specialization facts are green because collectors skip
   absent rows.
2. They skip rows because the audit treats sidecars as optional observations.
3. Consumers treat the same sidecars as semantic inputs, sometimes with
   fallback behavior.
4. No required-node inventory joins AST/MIR demand to Sema production.
5. Therefore the audit proves internal shape of existing data, not completeness
   of the compiler contract.

### Proper repair boundary

- Define which AST node kinds require a resolved type after successful Sema and
  validate every reachable required node.
- Join every `MirBody` whose symbol is a monomorphized generic and every MIR call
  with `call_contract_required=true` to exactly one concrete descriptor.
- Reject invalid/zero/out-of-range type IDs and origin-file mismatches.
- Keep syntax-only/type-expression nodes explicitly exempt by named rules;
  never infer exemption from absence.

## Finding 3 — medium candidate: comptime is a duplicated, allowlisted semantics engine

Classification: **architecture risk / candidate unreported equivalence gaps**  
Severity: **Medium**, rising to High for ownership or error-propagation drift  
Confidence: **High** for duplication and coverage gaps; no new runtime mismatch
was reproduced in this pass

`ComptimeEval.w` contains at least 16 explicit `not comptime-evaluable yet`
failure sites. It independently implements Vec, byte-vector, HashMap, Option,
str, StringBuilder, integer, type-object, pipeline, call, match, and default
value semantics. That is not inherently wrong—the spec forbids ambient effects
at comptime—but every pure operation implemented twice is a drift seam.

The differential target contains six fixtures:

- `cd_control.w`
- `cd_map.w`
- `cd_str.w`
- `cd_strbuild.w`
- `cd_unary.w`
- `cd_vec.w`

The corpus does not directly differentially cover generic specialization,
Copy/drop ownership, Result and `?`, errors, reflection, enum payloads, pattern
composition, early return/break/continue cleanup, or nested user-defined calls.

### Proper repair boundary

Long-term, pure comptime execution should consume the same typed operation
contracts as runtime/MIR rather than maintain independent method-name
allowlists. Until then, expand differential matrices by semantic category and
require both phases to produce the same value, diagnostic class, ownership
effects, and cleanup result.

## Confirmed sound mechanism — generic type-instance cache collision defense

No defect was established in `generic_inst_cache` during this pass.

`sema_generic_inst_hash` (`src/Sema.w:3614-3618`) is not collision-free, but
`find_generic_inst_type` (`3621-3652`) validates the cached type kind, canonical
base symbol, argument count, and exact argument list before returning it, then
falls back to a full type-table scan. `ensure_generic_inst_type`
(`3654-3666`) creates a new identity only when no exact instance exists.

This is a useful working control: hashed lookup is merely acceleration; the
full structural identity is authoritative. Any repair to function
specialization should preserve this property rather than treat a hash or
rendered name as identity.

## Bounded executable matrix

All commands used the current-ledger-bound `out/bootstrap/bin/with-stage1`;
they do not substitute for an independent clean rebuild or fixpoint attestation.

| Probe | Result |
|---|---|
| D21 generic comptime pipeline: `check --validate-all` | exit 0, `validate-all: ok` |
| D21 generic comptime pipeline: `run --debug-alloc` | exit 0, `ok` |
| `cd_vec.w`: check + allocator run | exit 0, `ok`, leak count 0 |
| `cd_map.w`: check + allocator run | exit 0, `ok`, leak count 0 |
| §17.2 generic TypeInfo fixture | exit 0, `ok`, leak count 0 |
| §17.4 generic comptime cascade fixture | exit 0, `ok` |
| §17.7 erased-branch fixture | exit 0, `ok` |
| taken invalid branch negative control | exit 1 with expected unknown-method diagnostic; validation did not run after compile failure |
| D21 `analyze ... audit:phase` | exit 0, 0 violations |
| D21 `analyze ... audit:all` | exit 0, 0 violations |

## Required regression matrix

### Type and sidecar completeness

- Every value-producing AST node kind, nested in each expression position.
- Cross-file imports with identical local node numbers and symbol spellings.
- Type expressions versus value expressions; generated versus parsed nodes.
- Invalid zero/out-of-range TypeId injection.
- Consumers run with one required sidecar deliberately removed; all must fail
  loudly before codegen.

### Generic specialization

- Same generic call node instantiated with Copy and non-Copy types.
- Same generic body instantiated in two files and two modules.
- Recursive and mutually recursive generic calls.
- Generic methods for read/mut/move receivers and Unit/non-Unit returns.
- Generic aggregate return by direct and indirect ABI.
- Nested generic structs/enums, trait bounds, closure arguments, async results,
  and drop glue.
- Hash collisions and same-text/different-symbol IDs must resolve to one exact
  structural TypeId, while structurally different arguments remain distinct.

### Comptime/runtime equivalence

- Success values and exact integer width/signedness.
- Diagnostics for overflow, invalid casts/indexes, and unsupported effects.
- Vec/Map/String ownership, overwrite/remove/pop transfer, and allocator
  cleanliness in both phases.
- Option/Result, `?`, `??`, match patterns, loops, early exits, and generics.
- TypeInfo/reflection and generated code re-entering normal type/borrow checks.
- Current-ledger-bound stage facts must be explainable by traced producer paths;
  an independent rebuild/fixpoint should confirm the same counts later.

## Existing issues and adjacent records

- #747: historical typed-expression sidecar-gap class (async block, `??`, join,
  raw/reference cases), explicitly called out in `docs/handoff.md:446-450` as
  needing a completeness audit.
- #766: generic comptime pipeline carrier, recorded closed in
  `docs/handoff.md:98-104`; its fixture is a passing control here.
- #767: sidecar recording contract, recorded as re-scoped/open in the same
  handoff. The current producer/completeness finding directly overlaps it.
- #589, #665, and #730 are regression-history locators for generic TypeInfo,
  comptime map Option behavior, and comptime ownership transfer respectively;
  issue text was not used as truth.

Candidate unreported issues from this audit:

1. Direct search did not locate the ordinary `typed_expr_types` producer while
   current-source-bound stage1 reports thousands of rows; the indirect/live
   producer path remains unexplained.
2. Direct search did not locate the concrete-specialization descriptor producer
   and found `generic_specialization_cache` unused, while stage1 reports
   specializations; distinguish indirect production from dead scaffolding.
3. Phase/all audits do not enforce sidecar or specialization completeness.

## Limitations and completion statement

- No independent clean stage rebuild, fixpoint, Windows/backend matrix, malformed-state
  injection, recursive-generic stress case, or full six-file comptime
  differential target was run.
- The repository-internal cache ledger binds local stage1 to current declared
  inputs and the recorded seed; it is not independent reproducible-build or
  fixpoint evidence.
- Local stage1's passing behavior is a control only; it does not identify the
  indirect producer or prove sidecar completeness.
- No module is checked complete. `Sema.w`, `SemaCheck.w`, `ComptimeEval.w`,
  `ComptimeTransform.w`, `Mir.w`, `MirLower.w`, `Analysis.w`, `Codegen.w`,
  `CCodegen.w`, and the related tests remain open across other audit targets.

The next trustworthy action is tracing the live producer/authority path,
followed by the required negative completeness injections and independent
question-driven rebuild/fixpoint evidence—not a semantic patch guessed from a
field-name search.
