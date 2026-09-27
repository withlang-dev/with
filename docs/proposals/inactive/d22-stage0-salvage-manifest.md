# D22 Stage 0 Salvage Manifest

**Status (2026-07-23): Stage 0 extraction complete; implementation remains in progress.**

This is a source-control and hunk-classification record subordinate to
[`d22-Eric-Ruling.md`](d22-Eric-Ruling.md). It does not add or reinterpret D22
semantics.

## Recovery points

- Doctrine baseline: `7a338abaf6a4211d44390570e4bf3210b959fce7` on `main`.
- Exact mixed-worktree rescue: `d533ca638c11646ff1a5eb925535271e79a7992f`
  on local branch `wip/d22-mixed-rescue-20260723`.
- The rescue commit contains every tracked and untracked file that existed
  before Stage 0. It is intentionally not pushed as D22.
- Canonical ruling and implementation-plan files were clean before the rescue
  snapshot and were not modified by the extraction.

## Reapplied D22 candidate hunks

These hunks were reviewed by function and reapplied on top of the doctrine
baseline. Their presence means only “in D22 scope”; later stages still own the
semantic and runtime proofs.

### `src/Sema.w`

- `Sema` contextual-adjustment sidecars: replace the call-only
  `auto_copy_ref_args` record with `contextual_copy_targets` and
  `contextual_join_payload_targets`.
- `sema_empty_state`: initialize the two D22 maps.
- `preregister_mir_types`: distinguish the owned `Option[V]` needed by remove
  from the borrowed carrier used by get.
- `expr_view_depends_on_origin`: stop an origin only at a Sema-recorded
  contextual-Copy ownership boundary.
- `type_needs_drop`: classify compiler-backed HashMap, HashSet, and SlotMap
  handles as owning allocations whose opaque fields require explicit drop
  glue. The existing Vec classification remains unchanged.

### `src/SemaCheck.w`

- One contextual-Copy predicate and one Sema-owned adjustment record.
- Independently established demands for calls, constructors, typed bindings,
  assignments, returns, casts, fields/elements, operators, and range bounds.
- One order-independent join resolver used by `if`, `match`, sequences, `??`,
  `unwrap_or`, and `unwrap_or_else`, including diverging arms and non-Copy
  classification.
- Exact Option/Result payload typing, `copied`/`cloned` bounds, and concrete
  Clone-call contract recording.
- Transparent origin collection, transfer, union, returned-view effects,
  pattern-binding propagation, generic-call propagation, closure/call-carrier
  propagation, and mutation-after-live-view diagnostics.
- Option/Result and user-Try origin transfer hooks.
- Transparent generic carriers may contain ephemeral references while actual
  long-lived storage containers remain forbidden.
- Builtin receiver-mode and generic-method lookup support used by D22
  Option/Result ownership boundaries and generic collection methods.

### `src/MirLower.w`

- Consume Sema's contextual-Copy record instead of the old call-only sidecar.
- Lower a contextual copy from the exact shared-reference place, then apply an
  ordinary post-copy value cast when recorded.
- Lower `??`, `unwrap_or`, and Result defaulting from exact payload places and
  consume Sema's recorded join-payload adjustment.
- Lower `Option[&T].copied()` and `.cloned()` as explicit owned boundaries.
- Preserve exact payload behavior for unadjusted Option/Result operations and
  use the resolved Clone contract.

### `lib/std/collections.w`

- BTreeMap internal checked entry view.
- Uniform `BTreeMap.get -> Option[&V]`.
- Ownership-preserving insert reconstruction and owned remove extraction for
  non-Copy keys and values.

No public Vec lookup signature was changed. The rescue's `Vec[T: Clone].clone`
rewrite was not reapplied.

### `rt/rt_core.w`

- SlotMap capacity, occupancy, and value-address helpers needed by typed drop
  iteration.
- SlotMap allocation release helper.

The HashMap nullable-pointer lookup and HashMap free primitive were already in
the committed baseline; no mixed runtime string/Vec ABI hunk was reapplied.

### `src/CodegenDispatch.w`

- Recover the SlotMap element type from the MIR/Sema snapshot.
- Iterate occupied SlotMap entries and emit typed element drops before freeing
  the backing allocation.
- Route SlotMap handles through their explicit drop path.
- Drop live HashMap/HashSet elements before `clear` erases occupancy.

No string representation, string ABI, formatting, or string-drop hunk was
reapplied.

### D22 evidence and migration files

The paths below record where Stage 0 recovered each file. Stage 1 subsequently
moved every listed fixture, unchanged except for explicit acceptance metadata,
into `test/non_compliant/d22/`; see that directory's README for its current
owner stage and verdict.

- Negative origin, join, generic, and diagnostic evidence:
  - `test/compile_errors/err_d22_btreemap_origin_after_clear.w`;
  - `test/compile_errors/err_d22_closure_capture_preserves_view.w`;
  - `test/compile_errors/err_d22_diverging_default_preserves_view.w`;
  - `test/compile_errors/err_d22_expect_origin_after_clear.w`;
  - `test/compile_errors/err_d22_if_join_origin_union.w`;
  - `test/compile_errors/err_d22_inferred_return_preserves_view.w`;
  - `test/compile_errors/err_d22_named_borrowed_default_remedy.w`;
  - `test/compile_errors/err_d22_nested_pattern_origin_after_clear.w`;
  - `test/compile_errors/err_d22_nonclone_default_remedies.w`;
  - `test/compile_errors/err_d22_raw_pointer_not_contextual_copy.w`;
  - `test/compile_errors/err_d22_result_origin_after_clear.w`;
  - `test/compile_errors/err_d22_result_unwrap_or_origin_union.w`;
  - `test/compile_errors/err_d22_tuple_origin_after_clear.w`;
  - `test/compile_errors/err_d22_unwrap_or_origin_union.w`;
  - `test/compile_errors/err_d22_user_try_origin_after_clear.w`.
- Positive contextual-Copy, exact-type, forwarding, and keyed-map
  ownership/drop evidence (later stages own activation):
  - `test/debug_alloc/da_d22_btreemap_get_borrow_remove_owned.w`;
  - `test/debug_alloc/da_d22_contextual_copy_positions.w`;
  - `test/debug_alloc/da_d22_contextual_default_eliminators.w`;
  - `test/debug_alloc/da_d22_direct_vec_storage_reborrow.w`;
  - `test/debug_alloc/da_d22_map_get_origin_excludes_key.w`;
  - `test/debug_alloc/da_d22_nested_join_value_context.w`;
  - `test/debug_alloc/da_d22_option_view_ownership_boundaries.w`;
  - `test/debug_alloc/da_d22_result_carrier_forwarding.w`;
  - `test/debug_alloc/da_d22_sequence_join_materialization.w`;
  - `test/debug_alloc/da_d22_slotmap_contextual_copy.w`;
  - `test/debug_alloc/da_d22_uniform_generic_map_forwarding.w`.
- `test/debug_alloc/da_slotmap_owned_storage_drop.w`: Stage 6 SlotMap ownership
  and drop control.
- `tools/migrate_d22_copy_views.w`: Stage 9 candidate. It applies only
  compiler-proven diagnostic fix-its and does not infer intent from `.get()`
  spelling. Its extern signatures were restored to the current share-place
  contract; the unrelated `&str` migration was removed.

## Quarantined mixed hunks

The following hunks remain recoverable only on the rescue branch. They are not
part of the extracted D22 worktree.

### Wrong parameter-mode or source-signature migration

- Every broad `str -> &str` declaration change.
- Comments or code asserting that plain `T` consumes by default, weakening or
  superseding D5 SHARE-PLACE, or treating inferred effects as obsolete for the
  current calling convention.
- Mechanical local type annotations added solely to migrate the compiler under
  that unrelated parameter-mode change.
- Runtime, compiler, standard-library, build, and tool call-site adaptations
  for the same migration.

Files wholly quarantined in this class:

- `build/selfhost.w`;
- `lib/std/build.w`, `builtins.w`, `compiler.w`, `fs.w`, `http.w`, `io.w`,
  `net.w`, `os.w`, `process.w`, `regex.w`, `string.w`, `testing.w`, `tls.w`;
- `lib/test/bench.w`;
- `rt/cimport_stubs.w`, `compat_runtime.w`, `darwin_aarch64.w`,
  `fiber_runtime.w`, `linux_x86_64.w`, `panic_runtime.w`, `regex_runtime.w`,
  `windows_x86_64.w`;
- `src/Archive.w`, `Ast.w`, `BuildGraphRuntime.w`, `BuildGraphTools.w`,
  `CImport.w`, `CiIR.w`, `CiMigrate.w`, `CiPrint.w`, `CodegenTraits.w`,
  `ComptimeTransform.w`, `ComptimeValue.w`, `Diagnostic.w`, `Fmt.w`,
  `InternPool.w`, `Lsp.w`, `Migrate.w`, `Mir.w`, `Parser.w`,
  `ReceiverMigration.w`, `Resolve.w`, `Scaffold.w`, `SemaDecl.w`,
  `SemaDiag.w`, `Source.w`, `Token.w`, `bootstrap_main.w`, `main.w`;
- `src/compiler/ClangBridge.w`, `CodegenUnits.w`, `DriverOptions.w`,
  `EmbeddedClangResource.w`, `Runtime.w`, `foundation/Diagnostic.w`,
  `foundation/Source.w`;
- `src/tools/generate_embedded_stdlib.w`;
- `test/behavior/behav_async_scope_panic_cancels_siblings.w`,
  `test/behavior/lib/pre_d_build_runner.w`,
  `test/codegen/regex_literal_code_abi.w`, `test/hello.w`;
- `tools/annotate_receivers.w`, `debug_drop.w`, `drop_audit.w`,
  `materialize_predicate.w`, `migrate_method_arg_moves.w`,
  `migrate_receivers.w`, `move_audit.w`, `with-sha256.w`.

Mixed-file hunks quarantined in this class:

- `src/Sema.w`: runtime extern signatures, D5/parameter-mode comments and
  TODOs, legacy classifier commentary, `str` Copy/drop reclassification, and
  mechanical local annotations.
- `src/SemaCheck.w`: runtime extern signatures, wrong-D5 comments, and
  mechanical local annotations.
- `src/MirLower.w`: runtime extern signatures, wrong-D5 lowering comments, and
  mechanical local annotations.
- `src/CodegenDispatch.w`: every string ABI, tagged-length, formatting,
  intrinsic, and string-drop hunk.
- `rt/rt_core.w`: allocator-range changes; owned/tagged-string layout and drop;
  string operations; Vec string-transfer/bootstrap ABI; filesystem/process
  string signatures; and string collection helpers.

### Suspect collection work requiring a fresh proof

- `lib/std/collections.w`: the rescue rewrote `Vec[T: Clone].clone` to copy raw
  elements from storage. That does not implement the declared Clone contract
  for non-Copy T and is not authorized by D22.
- `test/debug_alloc/da_vec_clone_body_control.w` and
  `da_vec_clone_copy_elements.w` remain rescue-only evidence for that separate
  issue.

### No uncommitted D22 behavior to salvage

- `src/CCodegen.w`: only unrelated string signatures, tagged string length,
  and string-drop emission changed. D22 C-backend parity remains future Stage 7
  work.
- `src/ComptimeEval.w`: only unrelated string signatures and a TODO wording
  change were uncommitted. The existing committed HashMap view snapshot remains
  subject to Stage 7 proof.
- `src/Codegen.w`: only string ABI and mechanical annotation changes were
  uncommitted.

### Test evidence outside D22

- `test/debug_alloc/da_fstring_i32.w`;
- `test/debug_alloc/da_str_shared_param.w`.

These remain available in the rescue commit and are not part of D22.

## Stage 0 gate audit

- The canonical ruling and active doctrine remain clean.
- The complete mixed state is recoverable from the local rescue branch and
  commit above.
- The extracted implementation paths are limited to D22 Sema, MIR, keyed-map,
  drop, diagnostic, fixture, and migration candidates.
- No unrelated `str` signature/runtime migration, bootstrap ABI migration,
  general parameter-ABI change, wrong-D5 doctrine, public `Vec.get` change, or
  suspect `Vec.clone` rewrite is present in the extracted worktree.
- Per the implementation plan, no build was required for this source-control
  gate. Stage 1 subsequently placed and indexed the fixtures without changing
  this salvage classification.
