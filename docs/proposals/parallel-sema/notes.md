chunk1 key facts:
- generic specializations checked lazily inside caller bodies (check_fn_body_concrete), first caller triggers; concrete_specialization_* GROW tables (spec index = registration order, observable: MIR iterates); concrete_drop_sigs/mono_syms first-wins memo keyed by TypeId.
- many RESULT-LOCAL NodeId-keyed tables are last-write-wins across specializations of one generic body (btree_insert_*, clone_contract_*, call_callable_types (TypeId), call_resolved_*, comp_resolved (also cross-body read by expr_may_suspend)).
- pooled flat vecs with offsets (call_resolved_args_data, c_promoted_arg_data(TypeIds), contextual_join_arm_*, contextual_copy_adjustments(struct w/ 4 TypeIds)) -> rebase on merge.
- body_typed_sigs: order-dependent diagnostic.
chunk2: contextual_join_* pooled with absolute offsets + TypeIds (MIR reads); debug_fmt_* global table keyed by TypeId, first-asker order, MIR iterates all, synth name __with_debug_fmt_{tid} embeds TypeId, add_sig during bodies; deferred_callable_forwards / deferred_closure_arg_checks appended across bodies, consumed by later fixpoint, diag order = list order; declared_write_* flat w/ offsets; current_module_path/current_module_has_ci ambient shared (MIR/codegen mutate it too); discarded_tails latest-verdict-wins.
chunk3: fn_may_alloc RESULT-CROSS read by later bodies -> order-dependent diagnostics; dyn_impl_* first-wins keyed by TypeId, rows order-dependent, read by codegen; dyn_downcast_binding_syms / facade_touch_hit_params never cleared keyed by name -> diag text depends on earlier bodies (latent order bug); field_last_use/binding epochs global counter.
chunk5: named_types MODULE but bodies temporarily insert Self/type params (save/restore) -> shared map mutated; mres_* trace rows shared; module_path_by_file lazy cache filled during bodies; local_file_id ambient.
chunk6: sig_param_effects / sig_param_view_origins / sig_param_invoke_many / sig_ret_types: summaries written by body, read by callers' checks (other-body) -> order dependence (#1473/#1783 ordering exists for view origins). operator_method_*, pattern_value_syms: generic bodies rechecked per instantiation, last write wins. sig tables GROW (add_sig during bodies; mono re-check overwrites sig rows in place). resolved_call_sigs iterated by keys() in AnalysisResolution.
chunk4: generic_specialization_cache key text embeds TypeIds; mono sym interned as name__sema__{key} => emitted symbol names embed TypeId numbers. global_calls/targets/bindings/dispatchers: ids = append order, baked into cross refs, BundleInterfaceEmit reads. gen_for_each_syms read cross-body via expr_may_suspend (order-dependent). global_race_*: first-wins scalars, append order = diag order; global_race_mutated_syms read during bodies (order-dependent). generic_subst_* scratch stacks shared with MIR/TypeLayout/Comptime.
chunk7: typed_expr_types (main node->type table) rewritten by check_fn_body_concrete on generic nodes, last instantiation wins, called from caller bodies AND MirLower. suppress_errors global counter. untyped_callee_calls order-dependent. type_extra GROW mixed values.

## October 1 continuation

The original inventory above records the September 30 tree. Current dispositions:

- Direct closure argument escape checks use completed parameter effects;
  capture summaries retain the checked capture type after the binding scope
  exits. Generic and cached generic calls record the same parameter edges as
  ordinary calls. Raw validity contracts read canonical declarations.
- Dynamic drop traversal reads impl target types resolved in the declaration's
  lexical module. Diagnostic spans and generic declaration facts read source
  identity owned by their AST node/canonical declaration.
- `dyn_downcast_binding_syms` is active binding scratch, removed at scope exit.
  The failing-first regression covers cross-function and same-body name reuse.
- The early `global_race_mutated_syms` read affected unused-unsafe diagnostics.
  Global reads now keep their enclosing unsafe-block nodes; the completed
  mutation facts decide those blocks after body checking. Definite raw/write
  operations remain immediate evidence. Late bodies use completed facts.
  Function-body checking also saves and clears lexical unsafe context, then
  restores the caller: a safe generic callee's internal runtime operation
  cannot make its caller's otherwise unused unsafe block necessary.
- `facade_touch_hit_params` has a different producer/consumer contract: the
  sole producer poisons the active binding and writes its parameter marker in
  the same branch; its consumer requires that binding's poisoned origin and
  the corresponding `facade_touch_nodes` entry. Domain diagnostics ignore the
  parameter marker. Historical entries therefore do not establish the
  downcast-style order bug. It remains worker scratch for S2b.
- `fn_may_alloc` judgments are deferred to `resolve_allocating_callees`.
  Inferred returns, return-view origins and receiver-stored views retain the
  explicit callee-first dependencies; callable invocation counts and argument
  escape judgments are finalized after propagation. These are prerequisites
  for dependency waves, not permission to share mutable worker state.

Grow-table ids, pooled offsets, generic-node last-write results and ambient
context still require S1/S2b before concurrent checking. A zero-difference
compile-error scan is acceptance evidence for its corpus, not proof that those
tables are ready for parallel workers.
