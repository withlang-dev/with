# MIR/Sema hardening — one owner per semantic fact

Status: PLAN (2026-09-25). Decision: `docs/meetings/2026-09-25-D65-one-authoritative-producer-per-semantic-fact-sema-decides.md` D65. Rule text:
`CLAUDE.md` "One owner per fact". Executable check: `with analyze
audit:resolution` (#1647). Sequenced after modeled C lands and alongside,
never ahead of, `docs/proposals/stdlib_sourcing_plan.md` phase 3 (STC).

## 1. The problem, in this week's bugs

Every Sema-vs-MIR-vs-codegen incident of 2026-09-22..25 was one defect in
different clothes: **two layers independently deciding one semantic fact**,
and disagreeing.

| Bug | The fact | Owner | Who re-derived it | Cost |
|---|---|---|---|---|
| #1635 `let r = c.run; r(21)` → `GENERIC_CALL` to a fn named `r` | what the ident `r` refers to | Sema (`typed_expr_types`, the view binding) | MirLower `lower_expr` NK_CALL dispatch: `lookup_local(r)` failed → "unresolved bare function" | build runner dead; 3 wrong fixes; ~6 h |
| `&fn` marshalling crash (jump into instruction bytes) | how a callable argument is passed | ABI (`FnAbi`/`PassMode`, D6) | codegen `marshal_ref_addr`: "the LLVM value is already a pointer → pass through" | complexity harness segfault |
| #1605 `spawn_os(move ‖ …)` double free | whether the closure owns its environment | Sema (D63 environment storage) | codegen `spawn_os` path transmuted and dropped independently | leak/double free |
| stage 13 rows refused by 12b/D64 | whether a facade row renders a safe call | Sema (`ci_syms`: c_import translation vs extern seam) | `verify_facade_buffer_params` refused every row with an unpaired pointer | stack battery red |
| #1639 / `audit:contract ok` over a refused program | is this MIR / this analysis result valid | the validator (post-Sema invalid MIR = compiler bug) | validators tolerated a 0-arg call to a 1-arg callee; analyze returned `ok` after `has_errors()` | silent |
| #1631 stage1 ≠ stage2 on `src/main.w:2992` | move state of `actual_options.source_path` | Sema (per operation) + MIR (per path) | pinned (PR #1656): `field_move_path_for_expr` packed the path start into 16 bits of an i64; `borrow_path_data` is append-only and passes 65535, so the move query read a stale path — a verdict that depended on unrelated source text | iterate tier untrustworthy |

The pattern predates this week: the transparent `T*`/`T**` divergence that
produced the FnAbi rule (D6) was the ABI-level instance of the same thing.

## 2. The rule (D65, verbatim)

Each semantic fact has one authoritative producer. Downstream stages may
propagate, materialize and verify that fact; they may not reconstruct or
override it from syntax or representation.

```
Sema-owned           resolved declaration; resolved type; place/value/view
                     category; view origin; operation effect (read, borrow,
                     mutate, consume, escape, invalidate, preserve); closure
                     capture semantics (mode, access, environment storage,
                     call kind); call target / specialization; acceptance
MIR-owned            CFG; local storage and temporaries; path-sensitive
                     initialization / move state; exact drop points;
                     cleanup edges
ABI / codegen-owned  physical layout; direct/indirect passing (PassMode);
                     calling convention; concrete LLVM representation
```

Forbidden upward inferences: LLVM type → semantic category or passing mode;
MIR local-table lookup → meaning of a name; AST spelling → resolved callee
after Sema. Authority vs verification: MIR that finds Sema's constraints
unrealizable on a path reports the contradiction; it never picks a different
meaning. Smell test: if deleting a downstream heuristic could change which
programs are accepted, the boundary is wrong.

## 3. What already exists (do not rebuild)

The semantic tables are there; the defect is that MirLower and codegen often
consult syntax or their own tables *first*:

- Sema → MirLower: `typed_expr_types`, `typed_binding_types`,
  `resolved_call_sigs`, `resolved_generic_call_nodes`, `expr_view_param_origins`,
  `binding_view_dep_data`, effect summaries per signature/parameter
  (`sig_param_effects`, `sig_param_view_origins`, `sig_param_invoke_many`),
  `binding_closure_nodes`, `callable_clone_nodes`, `deferred_closure_arg_checks`,
  `drop_consumed_binding_values`, `auto_ref_binding_values`, the facade
  contract tables (`foreign_contracts`, `facade_presented_syms`, `ci_syms`).
- MIR → codegen: `FnAbi` with per-parameter `PassMode` (D6), MIR call
  facts, `analysis_last_marshal_strategy` (the codegen marshalling fact the
  analyzer already records).
- The analyzer: `with analyze` joins Sema, MIR and codegen facts per node
  (`audit:calls`, `audit:mir`, `audit:codegen`, `matrix:`, `explain:`);
  `audit:all` runs in `:dev` verification and the battery.

MirLower's own tables that shadow Sema's: `bind_syms`/`bind_local_ids`
(locals), `alias_syms`/`alias_places`/`alias_types` (view bindings),
`lookup_local`, `lookup_alias_place`, `sym_is_generic_fn` (matches by
symbol *text* through `pool_lookup_symbol`), `ident_names_local_callable`.
These are legitimate *materialization* state (which MIR local holds a
binding); they become defects when used to decide *meaning* (#1635).

## 4. Phases

### Phase 0 — doctrine (this PR)
D65 in `decisions.md`; the rule in `CLAUDE.md`/`AGENTS.md`; this plan;
#1647 filed. From now on: a bug fix moves the answer to its owner and adds
the corresponding `audit:resolution` check when cheap; a review rejects a
new heuristic that re-derives an owned fact.

### Phase 1 — `audit:resolution`, callees (would have caught #1635)
Status: implemented (PR for #1647; `src/AnalysisResolution.w`, the
comparison in `MirCore.w`, planted fixtures in `test/internals/`). The
validator half (#1639) landed with it.
For every MIR call fact with an AST node: the callee MIR resolved (a
`const fn` symbol, a local/alias place, a closure body, an intrinsic) must
agree with Sema's resolution for that node (`resolved_call_sigs`,
`resolved_generic_call_nodes`, `typed_expr_types` of the callee expression
being a callable type bound to a local/view). Any MIR `const fn` callee
whose symbol has no signature and no generic node is a violation (this also
closes #1639 without an allow-list: the builtin branch's legitimate calls
carry a `MirIntrinsic` and are recognized by it). Red in `audit:all`.
Fixture: `test/analysis/` planted configurations + `behav_callable_alias_field_call.w`.

### Phase 2 — codegen mode provenance (would have caught the `&fn` crash)
Status: implemented for the sites #1647 named (#1647, wave-d65). Each
site calls `Codegen.mode_decide(site, fact, llvm, …)`: the decision is the
owner's fact — FnAbi's PassMode (`fn_abi_param_by_address`, receivers by
place), Sema's category of a place step (`mir_place_step_holds_address`,
`mir_sema_type_is_raw_pointer`) or of an operand (`mir_operand_is_fn_item`,
`mir_sema_type_is_raw_pointer_or_ref`, `mir_param_slot_holds_address`) — and
the LLVM type is verification. `audit:codegen` (`audit_mode_provenance`)
reports per site; a disagreement is a violation. Before the change the lane
was red over `src/main.w` on all nine live sites; the two method-owner
fallbacks of the field walks never fired and were deleted. The downcast
sites and the null constant read the `Option`-of-pointer niche, which is
codegen-owned representation, and stay LLVM-typed. Not yet converted:
`mir_try_place_ptr_for_ref` (value-vs-slot by LLVM type and the name
`self`) and `mir_operand_local_holds_pointer`.
Every `analysis_last_marshal_strategy` must be derivable from the argument's
`PassMode` and the operand's MIR category, never from `wl_get_type_kind` of
the evaluated value. Concretely: `marshal_ref_addr`'s "already a pointer"
branch becomes `PassMode`-driven (`Direct` reference value vs
`IndirectPlace` vs a callable pair by value); the audit flags a marshalling
fact whose strategy was chosen by LLVM-type inspection (the codegen fact
records the reason; a `type-inspection` reason is a violation). Then the
`spawn_os`/transmute special path reads Sema's environment-storage fact.

### Phase 3 — places and origins
Status: implemented for field places and `let` bindings (#1647, wave-d65).
MIR records each place lowered from a source field access (node, place,
base) and each `let`'s materialization (alias or owning local); Sema
persists its binding category (`view_bound_let_nodes`). `audit:resolution`
judges them with `mir_field_place_verdict` / `mir_let_binding_verdict`
(planted in `test/internals/analysis_resolution_test.w`). Over `src/main.w`
the compiler already agrees: 70083 field places and 9155 bindings, 0
violations. Not yet covered: view origins (`expr_view_param_origins`)
and index places; the field projection still names its field by symbol,
not by Sema's declaration index.
Every MIR place lowered from a source expression must correspond to Sema's
resolved place/origin for that node: field index from Sema's declaration
identity (not from name lookup at lowering time — the module-type identity
and generic-payload bugs of #1446/#1442), autoderef depth from Sema's
category, alias/view origin from `expr_view_param_origins`. The audit
compares MIR place projections with Sema's canonical projection per node.

### Phase 4 — effects
MIR move/borrow/capture classification per operation must agree with Sema's
effect summary: a MIR `move` operand where Sema recorded observe (or vice
versa) is a violation; closure environments carry Sema's
`{storage, captures[{place, mode, access}], call_kind}` record and MirLower
materializes it without reconsidering (`lower_callable_expr` stops deciding
observe-vs-move). This is where D62/D63's remaining special cases collapse
into `MakeCallable / CloneCallable / DropCallable / CallCallable`.

### Phase 5 — MirLower cleanup (after STC)
Retire the AST-first lookups: the ident-callee dispatch in `lower_expr`
becomes "read Sema's resolution, materialize it" — one ordered switch on
the resolved kind (local callable, view callable, closure body, function
symbol, generic, variant constructor, distinct-type constructor, builtin);
`sym_is_generic_fn` stops matching by symbol text. Facade rendering emits
only ordinary calls plus effects; MIR knows nothing about facades. Done
when every `audit:resolution` category is on in `audit:all` and the
validators are strict (post-Sema invalid MIR fails the build with the
compiler named as the culprit).

## 5. Sequencing and batching

- Phase 0 now (docs only, `:spec-inventory-check`).
- Phases 1–2 as one batch, next after the current modeled-C stack: they are
  analysis lanes plus two codegen/MirLower sites; the isolation rule applies
  (they touch marshalling → `:drop-audit :move-audit`).
- Phases 3–4 batch with the bugs that expose them; each bug fix lands its
  audit check in the same PR ("fix, don't file" for the check).
- Phase 5 after `docs/proposals/stdlib_sourcing_plan.md` phase 3 ships — Eric's
  priority order: what users feel first.

## 6. Acceptance

- `with analyze <any fixture> audit:resolution` exists, is in `audit:all`,
  and is red on planted configurations for each of the four categories.
- The four bugs in §1 are covered by a category each and have fixtures.
- Grep-level: no `wl_get_type_kind(...) == wl_pointer_type_kind()` decides
  a passing mode in `CodegenDispatch.w`; no `lookup_local` decides what a
  name means in MirLower's call dispatch.
- `--validate-all` refuses a MIR call whose callee symbol has no signature
  and no intrinsic (#1639).
- The seed-built stage1 and the stage2 compiler agree on `src/main.w`
  (#1631 pinned: not two Sema times but a 16-bit path start; fix PR #1656)
  (#1631 pinned and fixed — its root cause is expected to be a Sema fact
  consulted at two different times).
