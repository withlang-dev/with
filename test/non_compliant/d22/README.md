# D22 NON-COMPLIANT Acceptance Matrix

**Status (2026-07-23): D22 is normative; implementation remains in
progress.** [`docs/meetings/d22-Eric-Ruling.md`](../../../docs/meetings/d22-Eric-Ruling.md) is
the sole authority for every fixture in this directory. This index records the
Stage 1 acceptance contract; it does not reinterpret the ruling.

## Lane contract

This directory is versioned and deliberately excluded from every ordinary
green test lane. The active compile-error and debug-allocator runners inspect
only `test/compile_errors/*.w` and the direct files in `test/debug_alloc`.
They do not recurse into `test/non_compliant/d22`.

Every `.w` fixture here starts with all six required facts:

- `owner-stage`: the first implementation-plan stage allowed to promote it;
- `required-verdict`: the final pass or failure contract;
- `exact-type`: the D22 type facts the program pins;
- `expected-diagnostic`: the required user-visible diagnostic, or `none`;
- `origin-set`: the required semantic view origins after each boundary;
- `drop-behavior`: the ownership and cleanup result, including allocator
  expectations where applicable.

Do not weaken a fixture to match current behavior. A stage may promote a
fixture only after all six facts are true. Promotion means moving the unchanged
program into the appropriate active lane and replacing the NON-COMPLIANT
metadata with that lane's executable directives. A passing current compiler is
not compliance evidence until the exact type, origin, and drop facts have also
been observed.

## D22 Section 14 coverage

| Ruling requirement | Named acceptance pins | Owner |
|---|---|---|
| §14.1 uniform HashMap/BTreeMap/SlotMap lookup and owned removal | `da_d22_uniform_generic_map_forwarding.w`, `da_d22_btreemap_get_borrow_remove_owned.w`, `da_d22_slotmap_contextual_copy.w` | 5–6 |
| §14.1 exact `unwrap`, `expect`, patterns, inferred returns, and generic forwarding | `exact_carrier_contextual_copy.w`, `origin_unwrap_after_clear.w`, `err_d22_expect_origin_after_clear.w`, `origin_pattern_after_clear.w`, `origin_result_pattern_after_clear.w`, `err_d22_inferred_return_preserves_view.w`, `da_d22_uniform_generic_map_forwarding.w` | 2–6 |
| §14.2 contextual Copy in typed bindings, returns, operators, arguments, fields, tuples, casts, assignments, receivers, and sequences | `da_d22_contextual_copy_positions.w`, `da_d22_sequence_join_materialization.w`, `copy_snapshot_survives_clear.w` | 5 |
| §14.3 no eager inferred copy | `origin_unwrap_after_clear.w`, `diagnostic_live_copy_view_remedy.w` | 4, 8 |
| §14.4 non-Copy ownership rejection | `noncopy_typed_binding.w`, `noncopy_default_diagnostic.w`, `err_d22_nonclone_default_remedies.w`, `err_d22_named_borrowed_default_remedy.w` | 8 |
| §14.5 every exact eliminator and transparent carrier retains origins | the Stage 4 origin inventory below | 4 |
| §14.6 contextual Copy, explicit clone, and remove end origins | `copy_snapshot_survives_clear.w`, `da_d22_option_view_ownership_boundaries.w`, `owned_remove_and_nll_controls.w` | 5–6 |
| §14.7 reference joins union every possible origin | `err_d22_if_join_origin_union.w`, `origin_if_join_fallback_after_clear.w`, `origin_default_union.w`, `all_reference_five_arm_join.w` | 4 |
| §14.8 mutation after final view use remains valid | `owned_remove_and_nll_controls.w` | 6 |
| §14.9 one generic borrowed contract and honest Copy/Clone/borrowed forms | `da_d22_uniform_generic_map_forwarding.w`, `generic_ownership_contracts.w` | 5–6 |
| semantic-engine and backend parity required by §14 | `comptime_contextual_copy_parity.w`, `backend_map_view_parity.w` | 7 |

## Owner-stage inventory

### Stage 2 — exact Sema types and one contextual adjustment

- `exact_carrier_contextual_copy.w` — explicit Option producer, exact inference,
  and independently demanded Copy results.
- `err_d22_raw_pointer_not_contextual_copy.w` — raw pointers never receive the
  shared-reference adjustment.

### Stage 3 — one order-independent join resolver

- `explicit_carrier_joins.w` — producer-independent reference, owned-anchor,
  and expected-type joins.
- `mixed_five_arm_join.w` — five-arm order independence and explicit
  stabilization.
- `diverging_loop_defaults_preserve_view.w` — `?? break` and `?? continue`
  preserve exact success types.

### Stage 4 — transparent-carrier origins and NLL facts

- `origin_explicit_option_after_mutation.w` — producer-independent Option
  construction and elimination.
- `origin_unwrap_after_clear.w` and `err_d22_expect_origin_after_clear.w` —
  exact Option eliminators.
- `origin_try_after_clear.w` and `err_d22_user_try_origin_after_clear.w` —
  built-in and user-defined `Try`.
- `origin_pattern_after_clear.w`, `origin_match_after_clear.w`,
  `origin_if_let_after_clear.w`, and
  `err_d22_nested_pattern_origin_after_clear.w` — exact structural patterns.
- `origin_result_pattern_after_clear.w` and
  `origin_refutable_for_after_clear.w` — `Ok(value)` and refutable `for`
  projections preserve exact references.
- `origin_additional_reference_layer.w` — nested projection preserves `&&T`
  instead of spending either reference layer.
- `err_d22_tuple_origin_after_clear.w`,
  `origin_ephemeral_struct_after_clear.w`, and
  `origin_ephemeral_enum_after_clear.w` — transparent aggregate carriers.
- `err_d22_result_origin_after_clear.w` — Result construction, function
  forwarding, and elimination.
- `origin_optional_chain_after_clear.w` and
  `origin_option_combinator_after_clear.w` — optional chaining and a
  non-owning combinator.
- `err_d22_inferred_return_preserves_view.w` and
  `err_d22_closure_capture_preserves_view.w` — inferred effects, returns, and
  closure capture.
- `err_d22_diverging_default_preserves_view.w` — `?? return` is a diverging
  fallback, not an owned anchor.
- `err_d22_if_join_origin_union.w` and
  `origin_if_join_fallback_after_clear.w` — both sides of an `if` origin union.
- `origin_default_union.w`, `err_d22_unwrap_or_origin_union.w`,
  `origin_unwrap_or_else_union.w`, and
  `err_d22_result_unwrap_or_origin_union.w` — Option/Result default joins and
  origin unions.
- `all_reference_five_arm_join.w` — removing the final owned anchor changes
  the inferred result to `&i32` and unions all reaching origins.

### Stage 5 — MIR lowering and focused runtime ownership

- `copy_snapshot_survives_clear.w` — a typed Copy snapshot is independent.
- `da_d22_contextual_copy_positions.w` — all single-value demand positions.
- `da_d22_nested_join_value_context.w` — enclosing demand reaches nested joins.
- `da_d22_sequence_join_materialization.w` — fixed-array and dynamic
  collection element join materialization.
- `da_d22_contextual_default_eliminators.w` — owned Option/Result defaulting.
- `da_d22_result_carrier_forwarding.w` — Result view forwarding followed by a
  contextual Copy boundary.
- `da_d22_option_view_ownership_boundaries.w` — explicit `.copied()` and
  `.cloned()` ownership boundaries.
- `owned_option_result_extraction.w` — consuming owned eliminators reset their
  wrappers and do not duplicate payload ownership.
- `da_d22_slotmap_contextual_copy.w` — already-uniform producer control.
- `da_d22_map_get_origin_excludes_key.w` — only the receiver, never the key, is
  a lookup-view origin.
- `generic_ownership_contracts.w` — honest Copy, Clone, and borrowed generic
  result contracts.

### Stage 6 — owning keyed maps and exact native drops

- `da_d22_uniform_generic_map_forwarding.w` — uniform HashMap forwarding for
  Copy and non-Copy values plus owned remove.
- `da_d22_btreemap_get_borrow_remove_owned.w` — BTreeMap lookup, replacement,
  removal, and destruction.
- `da_d22_hashmap_replace_owned.w` — HashMap replacement drops the displaced
  value and the unused consumed duplicate key exactly once.
- `err_d22_btreemap_origin_after_clear.w` — BTreeMap views retain their owner.
- `da_d22_direct_vec_storage_reborrow.w` — checked library-maintainer reborrow
  used by BTreeMap storage.
- `owned_remove_and_nll_controls.w` — remove transfers ownership and mutation
  after the final view use remains legal.
- `da_slotmap_owned_storage_drop.w` — retained and removed SlotMap values plus
  backing storage drop exactly once.

### Stage 7 — comptime and C-backend parity

- `comptime_contextual_copy_parity.w` — comptime, native, and C execution agree
  on contextual Copy from map lookup.
- `backend_map_view_parity.w` — native and C execution agree on non-Copy map
  views and owned removal.

### Stage 8 — normative diagnostics

- `diagnostic_live_copy_view_remedy.w` — full owner/view/mutation/later-use
  labels and the machine-applicable owned-type annotation.
- `noncopy_typed_binding.w` — non-Copy typed demand rejects implicit ownership.
- `noncopy_default_diagnostic.w` — normative non-Copy `??` diagnostic and only
  applicable remedies.
- `err_d22_nonclone_default_remedies.w` — no `.cloned()` suggestion without a
  Clone implementation.
- `err_d22_named_borrowed_default_remedy.w` — borrowed-default help must be
  lifetime-correct for a named fallback.

## Promotion record

No fixture is promoted during Stage 1. The ordinary active lanes are unchanged.
Later stages must update this section when moving a fixture, including the
candidate compiler, command, and evidence that exact type, origin set, required
diagnostic, and drop behavior all matched the header.
