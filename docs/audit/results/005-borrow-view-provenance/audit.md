# Borrow and View Provenance Audit

**Audit target:** 6 — borrow and view provenance, including D22 conformance  
**Revision audited:** `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
**Status:** Bounded audit complete; one independent defect confirmed, one precision limit remains a candidate, and known D22 implementation gaps remain deliberately non-compliant  
**Production changes:** None

## Executive verdict

The current implementation has a coherent semantic center for D22's exact-reference and contextual-Copy rules: Sema retains `&T`, records explicit contextual-copy and join decisions, and MIR lowering consumes those decisions rather than independently re-inferring them. The bounded executable matrix confirms exact reference preservation through representative carriers, unioned origins at joins, a positive NLL case, and a map lookup snapshot that survives mutation with no debug-allocator leaks.

The audit also confirmed one additional defect, **BVP-001**: destructuring a product whose components borrow different owners assigns the whole product's unioned origin set to every nested binding. This rejects safe code by claiming that one projected binding views an unrelated owner. It is related to D22 work, but it is not merely the documented temporary non-compliance: the implemented nested-pattern path is structurally unable to distinguish sibling origins.

The explicitly quarantined D22 work remains unfinished. In particular, MIR does not carry semantic origin facts, comptime parity is not established, and a non-Copy owned demand still emits only a generic type-mismatch diagnostic. Those are recorded below as deliberate current **NON-COMPLIANCE**, not as newly discovered independent defects.

## Authority and method

The controlling contract was `docs/d22-Eric-Ruling.md`. `docs/d22-implementation-plan.md` and `test/non_compliant/d22/README.md` were used only as derivative implementation/status material. No observed implementation behavior was treated as authority over the ruling.

Discovery used the repository knowledge graph first. Because its index did not expose the relevant With functions with enough fidelity, the audit fell back to bounded source inspection with Tilth. The audit then followed origin facts end to end through Sema state, expression and pattern propagation, call effects, contextual-copy/join sidecars, MIR lowering, map APIs, backends, diagnostics, and selected executable probes.

This is a report-only audit. It did not edit source, specs, tests, the audit overview, checklist, or index; it did not file issues or implement fixes.

## Provenance architecture found

### Semantic state and origin encoding

- `src/Sema.w:67-82` defines `BindingProvenance`. A binding has a flat `view_origin_mask` and a flat dependent-origin range (`view_dep_start`/`view_dep_count`); it has no projection-sensitive origin tree.
- `src/Sema.w:84-98` maps function parameters into a signed 32-bit mask. Indices at or above 31 return `-1`, and membership against a negative mask treats every parameter as present.
- `src/Sema.w:374-406` defines the structured `ContextualCopyAdjustment` and `ContextualJoinDecision` records.
- `src/Sema.w:931-945` stores contextual-copy and join records as sidecars; `src/Sema.w:959-964` stores typed expression/binding types and view-projection expression flags; `src/Sema.w:1030-1051` stores function return-origin effects plus binding/expression view-dependency tables.

### Exact references, contextual Copy, and joins

- `src/SemaCheck.w:368-395`, `can_contextually_copy_ref`, admits only shared `&T` where `T: Copy` and an owned type is already demanded. Raw-pointer/reference conversions are kept distinct.
- `src/SemaCheck.w:416-460`, `record_contextual_copy_adjustment`, records the decision against the current signature and expression node. Transparent grouping/block wrappers are normalized, and conflicting decisions are rejected.
- `src/SemaCheck.w:632-804`, `resolve_contextual_join`, is the single join authority. It ignores diverging arms, keeps all-reference joins exact, materializes Copy reference arms only for an already-owned join, unions reference origins, and records a structured join sidecar.
- Representative owned-demand consumers include typed bindings (`src/SemaCheck.w:9144-9212`), returns (`10192-10231`), call arguments, casts, operators, sequences, match joins (`12317-12379`), Option/Result defaults, and closure/body returns.

### Origin producers and consumers

- `src/SemaCheck.w:9600-9674`, `collect_expr_view_deps`, recursively unions origins through grouping, operators, blocks, conditions, tuples, enum/struct construction, arrays, and maps.
- `src/SemaCheck.w:9676-9739`, `compute_expr_view_origin_mask`, follows the same transparent expression families and clears the origin after contextual Copy. The result is still a flat set.
- `src/SemaCheck.w:9771-9796`, `record_view_binding_from_expr`, assigns the expression's complete dependency set to a binding and registers the resulting borrow.
- `src/SemaCheck.w:9798-9840`, `record_pattern_view_bindings`, recursively walks nested patterns but passes the unchanged whole `subject_node` to every nested binding. This is the exact branch responsible for BVP-001.
- Match uses that walker at `src/SemaCheck.w:12290-12379`, specifically after pattern checking at line 12331. Let-else uses it at `src/SemaCheck.w:14453-14474`, line 14463.
- Pattern types are separately projection-sensitive through `pattern_child_subject_type` and its callers (`src/SemaCheck.w:13570-13636`). Thus exact child types can be correct while child origins are not.
- `src/SemaCheck.w:10077-10105` maps a callee's return-origin effect mask back onto the caller's argument origins. The generator path has analogous handling at `10107-10132`.
- `src/Sema.w:5477-5510` checks active borrows and dependency masks before invalidation; `src/Sema.w:5193-5203` poisons live views; the NLL/borrow-expiry machinery begins near `src/Sema.w:7231`.

### MIR and other engines

- `src/MirLower.w:259-269` reads Sema's contextual-copy and join sidecars using the semantic signature key.
- `src/MirLower.w:9230-9270`, `lower_contextual_copy_adjustment`, lowers the exact reference first, materializes it, dereferences once, copies the referent, and performs an optional post-copy cast. `str` uses an independent concatenated owner.
- `src/MirLower.w:9272-9309` consumes synthetic join-arm adjustments. Every expression passes through the adjustment dispatch near `src/MirLower.w:12510-12515`; carrier/default joins also have dedicated consumers.
- No semantic origin-set representation or consumer was found in `src/Mir.w` or `src/MirLower.w`. The existing `--explain-mir-origin` surface is textual explanation rather than carried, validator-checkable provenance.
- No independent contextual-Copy/join/origin authority was found in `src/CCodegen.w`, `src/ComptimeEval.w`, or `src/Analysis.w`. C codegen consumes MIR, while comptime parity remains incomplete.

### Map-origin producers

- `lib/std/collections.w:98-102` gives `BTreeMap.get` the uniform `Option[&V]` surface; `lib/std/collections.w:126-131` gives `remove` the owned `Option[V]` surface.
- `lib/std/collections.w:71-75` exposes `key_at`/`value_at` as unsafe views into the backing vector.
- `HashMap` is opaque at `lib/std/collections.w:34-49`; its compiler-owned/intrinsic method surface was observed through the typed D22 probes rather than re-derived from that declaration.

## Bounded executable matrix

All rows except the explicitly noted bootstrap observation used a compiler built from the audited source revision with the installed `with v0.15.1.6`, at `-O1`:

| Probe | Expected discriminator | Observed result |
|---|---|---|
| `check exact_carrier_contextual_copy.w --dump-typed` | Exact carrier references remain references; owned demands receive explicit adjustments | Exit 0. Typed output retained inferred `&i32` through carrier/pattern paths and reported 35 contextual-copy adjustments. |
| `check origin_explicit_option_after_mutation.w` | A live Option-carried view prevents owner mutation | Exit 1 with owner, view binding, mutation, later-use labels, plus an owned-binding fix direction. |
| `check all_reference_five_arm_join.w` | A reference join unions all arm origins | Exit 1 when an origin represented by a fallback arm is mutated. |
| `check err_d22_nested_pattern_origin_after_clear.w` | Nested pattern preserves the lookup's map origin | Exit 1 with the required map/view diagnostic. |
| `check nll_condition_then_copy.w` | A view ceases to block mutation after its final use | Exit 0. |
| `run copy_snapshot_survives_clear.w --debug-alloc` | Owned contextual Copy is independent of the map and memory-clean | Exit 0; `debug-alloc: leak count=0`. |
| `check noncopy_typed_binding.w` | Non-Copy reference cannot satisfy an owned demand | Exit 1, but only with generic `type mismatch in binding`. This is an unfinished D22 diagnostic, not a new semantic defect. |
| `run comptime_contextual_copy_parity.w --debug-alloc` | Comptime and native observe the same D22 behavior | Exit 1 at `HashMap.new()` with `collection.new() requires a concrete generic type`. This is an unfinished parity stage. |
| New distinct-origin tuple repro | Projecting the first component must not borrow the second component's owner | Exit 1 incorrectly: `cannot mutate b while ra is a live view into it`. BVP-001 confirmed. |
| Same repro, mutating the actual owner | Negative control must still reject | Exit 1 correctly. |

The confirmed-defect repro was:

```with
var a = 1
var b = 2
let pair = (&a, &b)
let (ra, rb) = pair
b = 3
assert(ra == 1)
```

The repository's pre-existing release compiler (`v0.15.1.7-gc83b13f66`) could not build the audited revision: its debug allocator reported a corrupt vector header while dropping `__drop_struct_93`. The installed older compiler did build the same source successfully. This bootstrap interoperability observation was not reduced or attributed because it lies outside this audit's ownership and bounded scope.

## Confirmed independent finding

### BVP-001 — Pattern projections inherit unrelated sibling origins

**Classification:** Independent implementation defect within the in-progress D22 work  
**Severity:** Medium  
**Reach:** Tuple, struct, enum, Option, Result, and let-else destructuring when different components carry views from different owners  
**Confidence:** High  
**Safety impact observed:** False positive / valid code rejection; no unsound acceptance demonstrated

#### Exact failure chain

1. The tuple subject `(&a, &b)` has the unioned origin set `{a, b}`.
2. `record_pattern_view_bindings` recursively visits both bindings but passes the unchanged whole tuple expression node to each (`src/SemaCheck.w:9798-9840`).
3. `record_view_binding_from_expr` therefore collects `{a, b}` for `ra`, although `ra` is the projection at tuple index 0 (`src/SemaCheck.w:9771-9796`).
4. Mutation checking sees `b` in `ra`'s flat dependency set and reports that `ra` is a live view into `b` (`src/Sema.w:5477-5510`).
5. The negative control confirms that the protection of the true origin, `a`, is active; the defect is loss of projection precision, not absent borrow checking.

#### Five Whys

1. Why is safe mutation of `b` rejected? `ra` is recorded as borrowing `b`.
2. Why does `ra` borrow `b`? Every nested binding receives the subject's complete origin union.
3. Why is the complete union reused? The pattern walker tracks child types but not child origin projections.
4. Why can it not recover the first component's origin? The stored expression and binding provenance is a flat set, with no structural path-to-origin fact.
5. Why is a local exception insufficient? The same structural loss affects every transparent product/carrier and every consumer that projects a component; syntax-specific filtering would produce divergent rules and miss joins, closures, and returned projections.

#### Proper repair boundary

The repair belongs at the semantic provenance representation and its projection operations, not in the mutation diagnostic and not as a tuple-pattern exception:

1. Represent origin sets per semantic projection path for product/carrier values, while retaining a conservative aggregate set where required.
2. Make tuple/field/variant/transparent-carrier construction and projection transform those facts explicitly.
3. Have `record_pattern_view_bindings` bind each nested name from its corresponding projected provenance fact.
4. Union origins only across genuine control-flow alternatives for the same projected result.
5. Carry the selected projection origin through function effects and closure capture/return when a function returns one field of a carrier.
6. Preserve the existing exact-type and centralized contextual-Copy/join authorities.

## Candidate precision defect

### BVP-002 — Function-origin masks collapse at parameter index 31

**Status:** Source-confirmed capacity collapse; executable manifestation not tested  
**Severity:** Low to Medium  
**Reach:** Rare functions with at least 32 parameters whose returned view originates in a high-index parameter  
**Confidence:** High for the mechanism, Medium for current user-visible behavior

`sema_param_origin_bit` returns `-1` for indices at or above 31, and `sema_param_origin_mask_contains` treats every parameter as present when the mask is negative (`src/Sema.w:84-98`). Return-effect collection and caller remapping consume this representation in `src/SemaCheck.w` around lines 9694, 9901, 9968, and 10053-10087. A view originating in one high-index parameter can therefore be summarized as originating in all arguments, causing over-retention and false-positive invalidation.

The correct repair shape is an unbounded bitset or sparse parameter-index set shared by effect production and consumption, not a negative all-parameters sentinel. This remains a candidate until a bounded high-arity executable probe confirms the externally visible consequence.

## Deliberate current D22 NON-COMPLIANCE

The following observations match the repository's explicit in-progress status and are not reported as independent defects:

- The 66 `.w` fixtures under `test/non_compliant/d22` remain quarantined rather than promoted into normal green lanes.
- MIR does not yet carry semantic origin sets or validate them at transparent carrier/projection/ownership boundaries.
- Comptime parity is not established; the selected comptime map probe fails before exercising contextual Copy.
- C-backend parity was not established by this bounded matrix.
- The non-Copy owned-demand rejection lacks the normative D22-specific diagnostic and structured fix direction.
- The full native/comptime/C, debug-allocator, optimization, and validator acceptance matrix described by the implementation plan has not run.

These gaps must remain visible as conformance work. Existing lookup ownership, an origin lost through an eliminator, or backend-specific behavior must not be used as precedent against the ruling.

## Regression matrix for a repair

At minimum, a repair for BVP-001/BVP-002 should cover:

| Axis | Required cases |
|---|---|
| Product projection | Two distinct tuple origins; mutate unrelated owner accepted; mutate actual owner rejected |
| Nested carriers | `Option[(&A, &B)]`, `Result`, nested tuple patterns, and let-else with distinct origins |
| Nominal projections | Struct and enum fields, positional and shorthand patterns |
| Control-flow joins | One projected field with a multi-arm union while a sibling remains independent |
| Closures and calls | Capture/return of one projection; caller effect maps only the selected source argument |
| Contextual Copy | Copying one projected component clears origins only for the owned result, not sibling refs |
| NLL | Final use of one sibling view permits mutation without weakening another live sibling view |
| Effect capacity | Parameter indices 30, 31, and 32 retain exact, independent origin identities |
| Producers | HashMap, BTreeMap, and other view-producing containers; Copy and non-Copy values |
| Engines | Native, comptime, and C backend agree; debug allocator and MIR validators remain clean |

## Module impact

Deeply inspected:

- `src/Sema.w`
- `src/SemaCheck.w`
- `src/MirLower.w`
- `src/Mir.w`
- `lib/std/collections.w`
- canonical D22 ruling, derivative plan, quarantine README, and selected D22 fixtures

Inspected for direct consumers or parity boundaries:

- `src/SemaDiag.w`
- `src/ComptimeEval.w`
- `src/CCodegen.w`
- `src/Analysis.w`

Relevant but not deeply audited:

- `src/BorrowCfg.w`
- every individual container/view producer outside the selected map paths
- all 66 quarantined D22 fixtures
- every optimizer and backend path

No module is marked fully audited by this report. The confirmed repair boundary spans Sema provenance representation and propagation, function effect summaries, MIR origin representation/validation, and parity consumers. It should not require a lookup-signature change or a map-specific workaround.

## Limitations

- This was deliberately capped at the smallest discriminating executable matrix; it is not a full D22 acceptance run.
- No full build, full test suite, fixpoint, sanitizer matrix, C-backend matrix, or complete comptime matrix ran.
- The release-compiler bootstrap allocator failure was observed but not debugged.
- BVP-002 was not executed.
- No live upstream issue search was performed, so BVP-001 and BVP-002 are candidate-unreported rather than proven unreported.
- No production fixes, test additions, spec changes, or issue filings were authorized or made.

## Contract and final self-audit

The audit stayed within target 6 and produced only this report. It did not alter a touched spec or introduce normative terminology requiring a glossary change. No Observed/as-built spec statement was relied upon as contract; the canonical D22 ruling remained controlling. The work distinguishes explicit current non-compliance from additional findings and does not redefine success around passing probes. Against the repository production rules, revisions would be required before claiming D22 complete, but no revision is required to this bounded report beyond the explicit limitations above.
