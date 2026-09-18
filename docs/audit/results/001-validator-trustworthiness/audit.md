# 001 — Validator trustworthiness

Status: **In progress — validator/aggregate census complete; direct malformed-MIR injection remains**  
Inventory snapshot: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Executable evidence: current-input-bound `out/bootstrap/bin/with-stage1`
([Audit 009](../009-build-platform-harness-spec/audit.md))
Audit target: overview §1

## Scope and conclusion

This pass inventoried every MIR function named or advertised as a validator, all
of their direct aggregate and CLI callers, ordinary pre-codegen and LLVM-backend
gates, the integrated-analysis aggregates, and the build-system tests that claim
coverage.

The current validator stack is **not a trustworthy safety boundary**:

- `--validate-all`, `analyze audit:mir`, and `analyze audit:all` all accept the
  #916 program immediately before it performs an allocator-proven invalid free.
- “all” omits `validate_use_after_kill`.
- ordinary compilation gates only typed MIR; the LLVM backend independently gates
  only structural shape. Ownership and use-after-kill validation are not required
  before code generation.
- the green battery proves the tools can return success on one small valid fixture;
  it does not inject malformed MIR and does not run `audit:all` on the compiler it
  is shipping.
- running `audit:all` on `src/main.w` at this snapshot reports 129 violations and
  exits nonzero, matching known issue #742.

This is an evidence report only. No compiler, build, test, specification, or issue
tracker files were changed.

## Modules inspected

- [`src/Mir.w`](../../../src/Mir.w)
- [`src/MirLower.w`](../../../src/MirLower.w)
- [`src/MirSuspendCheck.w`](../../../src/MirSuspendCheck.w)
- [`src/Analysis.w`](../../../src/Analysis.w)
- [`src/Codegen.w`](../../../src/Codegen.w)
- [`src/CodegenTraits.w`](../../../src/CodegenTraits.w)
- [`src/compiler/Compilation.w`](../../../src/compiler/Compilation.w)
- [`src/main.w`](../../../src/main.w)
- [`build.w`](../../../build.w)
- [`test/spec/spec_ss14_11_await_combinator_cancel_joins.w`](../../../test/spec/spec_ss14_11_await_combinator_cancel_joins.w)
- `test/phase/*validate*.w` and the `typed_mir_*` phase fixtures selected by
  `--validate-all`

## Validator and entry-point matrix

| Validator/detector | Exact implementation | Ordinary pre-codegen | LLVM backend | `--validate-ownership` | `--validate-all` | `audit:mir` / `audit:all` | Synthesized const initializer |
|---|---|---:|---:|---:|---:|---:|---:|
| Structural shape | `Mir.w:2718-3042` | Yes, indirectly through typed validation | **Yes** | Yes, indirectly | Yes | Yes | No direct gate found |
| Typed MIR | `Mir.w:3501-3627` | **Yes** (`Compilation.w:1583-1595`) | No | No | Yes | Yes | No |
| Ownership debug | `Mir.w:2379-2428` | **No** | No | **Yes** | Yes | Yes | No |
| Use-after-kill | `Mir.w:2600-2658` | **No** | No for ordinary bodies | No | **No** | **Yes** (`Analysis.w:1122-1135`) | **Yes** (`CodegenTraits.w:1637-1648`) |
| Return consistency (adjacent analysis detector, not a MIR validator) | `Analysis.w:1137+` | No | No | No | No | `audit:returns` / `audit:all` only | No |

Additional entry-point facts:

- `Compilation.validate_all_file` (`Compilation.w:1413-1425`) lowers the file and
  calls `validate_all_mir_module`.
- `validate_all_mir_module` (`Mir.w:2660-2670`) calls shape, typed, and ownership
  only.
- `Codegen.gen_module_from_mir` (`Codegen.w:1268-1275`) reruns shape only before
  LLVM generation.
- `Analysis.analysis_audit_mir` adds use-after-kill after calling the incomplete
  “all” aggregate. `audit:all` includes that analysis pass, but remains opt-in.
- typed and ownership module validators skip bodies with `lowering_failed != 0`;
  analysis use-after-kill and return checks also skip them. Codegen skips such
  bodies. No active producer assignment for `lowering_failed` was found in the
  current source, so this is a dormant fail-open design risk rather than an
  executable finding in this pass.

## Finding VAL-001 — all advertised aggregates accept #916's corrupting MIR

Verdict: **Confirmed**  
Severity: **High**  
Reach: **Global verification surface; async/cancellation manifestation**  
Confidence: **High**  
Issue status: behavioral defect is reported as #916; the validator false-negative
may not be separately reported.

### Executable negative control

All three advertised aggregates returned success:

```text
./out/bootstrap/bin/with-stage1 check \
  test/spec/spec_ss14_11_await_combinator_cancel_joins.w --validate-all
validate-all: ok

./out/bootstrap/bin/with-stage1 analyze \
  test/spec/spec_ss14_11_await_combinator_cancel_joins.w audit:mir
mir-audit: facts=11872 violations=0 ok

./out/bootstrap/bin/with-stage1 analyze \
  test/spec/spec_ss14_11_await_combinator_cancel_joins.w audit:all
compiler-analysis-audit: facts=12582 violations=0 ok
```

The same compiler and fixture under the native allocator:

```text
./out/bootstrap/bin/with-stage1 run \
  test/spec/spec_ss14_11_await_combinator_cancel_joins.w \
  --debug-alloc --debug-alloc-filter=non-root
invalid free addr=<address> origin=drop#struct __drop_struct_94
panic: invalid free: pointer is not an allocated payload start
```

The validator commands exited 0. The allocator command exited 1.

### Exact false-negative chain

1. The cancelled `await_all[i32]` path reaches an ordinary MIR return without
   assigning return local `_0`; only its normal path assigns `_0`.
2. `Mir.w:1815-1825`, `mir_drop_state_transfer_term`, unconditionally marks every
   `TK_CALL` destination `Init` after noting its operands. There is no alternate
   completion edge or callee-return proof.
3. `Mir.w:2379-2415`, `validate_ownership_body`, therefore receives the same false
   state as lowering: the mere presence of a call is treated as proof of a value.
4. `Mir.w:3501-3614`, `validate_typed_mir_body`, checks call destinations only for
   `Vec.push` and the D21 receiver-place pipeline. It does not compare an ordinary
   callee's completion modes with destination initialization.
5. `Analysis.w:1137+` checks only Unit-return/destination disagreement and a
   Unit-typed switch subject. #916 has matching non-Unit signatures, so this
   adjacent detector also returns success.
6. The caller moves and drops the unwritten result, reaching the allocator's
   invalid-free guard.

### Root cause (5 Whys)

1. Why does the caller free garbage? It consumes an unwritten call destination.
2. Why is it unwritten? Cancellation returns through the callee without normal
   value production.
3. Why can the caller consume it? MIR represents a call with one unconditional
   value-producing successor.
4. Why do validators accept it? Their transfer and typed-call rules encode that
   same representation as an invariant instead of proving it.
5. Why does `audit:all` not catch the cross-function contradiction? There is no
   explicit MIR completion effect/edge joining callee exits to caller result use.

The deepest credible cause is representational: cancellation/alternate completion
is hidden runtime state, not explicit MIR control flow. Validation cannot prove a
normal result exists when MIR has no way to express that it might not.

## Finding VAL-002 — the shipping battery does not apply `audit:all` to the compiler

Verdict: **Confirmed**  
Severity: **High**  
Reach: **Global build/release verification gate**  
Confidence: **High**  
Issue status: the 129 violations are reported as #742; the false-green gate is a
candidate adjacent/unreported defect.

`build.w:1339-1399` generates one small valid ownership program. It asserts that
`--validate-ownership` prints `validate-ownership: ok` and that `analyze audit:all`
prints its verdict label. It contains no malformed-MIR rejection control and never
passes `src/main.w` to the analysis command. The phase fixtures located for
`--validate-all` are likewise success-path fixtures expecting `validate-all: ok`.

Current compiler-wide executable control:

```text
./out/bootstrap/bin/with-stage1 analyze src/main.w audit:all
...
compiler-analysis-audit: facts=2471682 violations=129 FAILED
```

Observed composition:

- 127 dominance-proven `use-after-kill` reports
- 2 frozen-phase mutable-Sema re-entry reports
- exit code 1

This matches the local triage record for #742. The important validator-audit fact
is not the already-reported count; it is that the build's positive smoke fixture
can pass while the product under test fails the same aggregate.

## Finding VAL-003 — production code generation is not ownership-validated

Verdict: **Confirmed from source**  
Severity: **High**  
Reach: **Every compiled MIR module**  
Confidence: **High**  
Issue status: candidate unreported architectural verification gap.

`Compilation.run_mir_lower` invokes `validate_typed_mir_module` and stops on its
error. It does not invoke ownership or use-after-kill validation. The backend then
invokes `validate_mir_module`, which is structural only. Consequently:

- a normal `check`, `build`, or `run` does not require ownership validation;
- `--validate-ownership` and `--validate-all` are opt-in diagnostics;
- the more complete `analysis_audit_mir` is also opt-in and already fails on the
  compiler itself;
- synthesized const initializers receive only the narrow use-after-kill scan, not
  the shape/typed/ownership aggregate.

## Finding VAL-004 — use-after-kill validation is intentionally partial

Verdict: **Confirmed from exact branches; user-visible consequence not separately demonstrated**  
Candidate severity: **High**  
Reach: **Any MIR body using a reset local outside the recognized straight-line shapes**  
Confidence: **High for detector gaps, Medium for undiscovered manifestations**  
Issue status: #742 proves many recognized hits; blind categories are candidates.

`validate_use_after_kill_body` has these exact limits:

- `Mir.w:2601-2603` returns success without checking when a body has more than
  20,000 locals.
- `Mir.w:2610-2655` examines only `Assign` statements. It does not inspect switch
  operands, call callees/arguments, drops, or other terminator uses.
- for an ordinary rvalue it treats only `rval_d0` as an operand. That recognizes
  `RK_USE` and happens to recognize casts, but not binop operands (`d1`/`d2`),
  unary operands (`d1`), string-concat argument tables, or slice bounds.
- aggregate fields receive a dedicated scan; the other multi-operand rvalues do
  not.
- `mir_block_reaches_linearly` accepts only same-block or increasing-index chains
  of `goto`/`call` single successors. Branch joins, back edges, and loops are
  deliberately excluded.
- comments in `Mir.w:2536-2542` and `Analysis.w:1126-1128` describe
  `StorageDead` as a kill class, but `Mir.w:2624-2629` explicitly ignores it. The
  implementation considers only reset-on-move zero fills destructive.

These are explicit early returns and unvisited operand fields. This pass did not
manufacture those table shapes inside the live compiler, so they remain
source-proven detector blind spots rather than executable user-program findings.

## Finding VAL-005 — typed validation covers selected rvalues, not typed MIR as a whole

Verdict: **Confirmed from exact branches; malformed-table injection pending**  
Candidate severity: **High**  
Reach: **Global MIR-to-codegen type contract**  
Confidence: **High**  
Issue status: candidate unreported validator-scope defect.

`validate_typed_mir_body` checks Assign destinations, selected place/use/slice
rvalues, membership/comparison/cast special cases, Drop targets, switch operand
existence, and two call special cases (`Vec.push` and D21 pipeline receivers).

It does **not** validate arithmetic/logical binop operand or destination types,
ordinary unary rvalues, aggregate field types versus aggregate/destination type,
array-fill types, string-concat types, general call argument types, ordinary call
return type versus destination type, or return-place initialization. The final
`continue` paths at `Mir.w:3570`, `3575`, `3587`, and `3612` make those omissions
exact.

## Finding VAL-006 — shape validation omits declared parallel-table invariants

Verdict: **Confirmed from source; malformed-table injection pending**  
Candidate severity: **Medium**  
Reach: **All MIR producers and backend consumers**  
Confidence: **High**  
Issue status: candidate unreported backend-contract defect.

`validate_mir_body` performs extensive bounds and length checks, but it does not
check these explicit `MirBody`/`MirModule` parallel contracts:

- `place_sema_types` length against the place tables;
- `agg_field_name_syms` length against aggregate operands;
- `call_intrinsic_kinds`, `call_ast_nodes`, `call_sig_indices`,
  `call_mono_syms`, and `call_contract_required` against call-argument table count
  (only `call_pipeline_receiver_places` is checked);
- semantic type snapshot `kind/d0/d1/d2` table lengths;
- ranges in `ever_moved_locals` and `mutual_tail_bbs`.

Several call-metadata accessors return `NONE`, `0`, or `-1` when the parallel row
is absent (`Mir.w:924-972`). A malformed producer can therefore lose intrinsic or
semantic-call metadata silently instead of being rejected by the backend-contract
validator.

## Proper validator boundary

A repair should establish one mandatory pre-codegen aggregate and prove it with
negative controls. At minimum:

- represent normal value completion, cancellation, divergence, and failure as
  explicit MIR control-flow/effect contracts;
- prove every ABI-required return place is initialized on every normal return;
- allow call-result use only on a value-producing successor;
- run shape, typed, ownership, use-after-kill, return consistency, and any future
  validator from one registry/aggregate rather than hand-maintained call lists;
- validate every declared parallel table and every operand-bearing rvalue/terminator;
- validate ordinary, generic-specialized, async/generator, comptime-generated,
  and codegen-synthesized bodies under the same contract;
- make the green battery inject one known-invalid MIR unit per rejection rule and
  run the aggregate on `src/main.w`, not only a toy valid program.

## Evidence limitations and remaining work

- Validator functions other than `validate_use_after_kill` are private to
  `Mir.w`. This pass did not complete an executable temporary harness that exposes
  them and injects hand-built malformed tables. The source branches above are
  confirmed; per-rule rejection tests remain required.
- #916 is the executable negative control for missing return initialization. It
  is not a substitute for one isolated invalid fixture per validator rule.
- [Audit 009](../009-build-platform-harness-spec/audit.md) establishes the
  repository-internal provenance for the executable used here: the stage1
  content-hash ledger and hashed seed manifest bind
  `out/bootstrap/bin/with-stage1` (SHA-256
  `d1f65fd87a450c24a00bf2498a9bc10f9cf55a42cb199c5d8ef667a2bb4cab1a`) to
  the inventory snapshot's current declared compiler, runtime, and standard
  library inputs; the recorded seed `/home/shawn/.local/bin/with` version
  `v0.15.1.6` (SHA-256
  `4a2d4d65272e550af2c9c8e27ecace8c841a9abcb951665445235d1376a6c38c`);
  and the recorded process effect. Its read-only stage explanation reported
  `fresh`. The `WITHVERSIONSTAMPv1...` text is the intentional unstamped stage
  sentinel, not ancestor evidence. This binding depends on the repository's
  cache implementation; a clean independent rebuild plus fixpoint remains
  stronger evidence and was not run.
- The report used the local issue triage for #742/#916 status. It did not query the
  live upstream tracker, so candidate-unreported labels are provisional.
- Full release, reseed, fixpoint, and test batteries were not run; this was a
  read-only diagnostic audit, and those batteries would not inject malformed MIR
  in their current source form.

## Module completion impact

No module is marked complete. The validator census is complete for this snapshot,
but `Mir.w`, `Analysis.w`, `Compilation.w`, `Codegen.w`, `CodegenTraits.w`,
`main.w`, and `build.w` remain open until isolated malformed-MIR rejection tests
and mandatory-gate coverage are established.
