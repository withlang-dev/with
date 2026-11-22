# Specification Test Cases

Test cases extracted from `docs/spec/guide/test-cases.md` (§25).
Each file tests one or more rules from the corresponding spec section.

Spec files started as pseudo-code sketches marked `//! skip`. As compiler
features are implemented, convert the pseudo-code to runnable tests and remove
the skip directive.

## Mapping

| Old Section | File |
|-------------|------|
| 25.1 | `spec_ss02_ownership_and_moves.with` |
| 25.2 | `spec_ss03_references_and_second_class_rule.with` |
| 25.3 | `spec_ss03_4_returning_references.with` |
| 25.4 | `spec_ss03_5_nll_borrow_scoping.with` |
| 25.5 | `spec_ss03_6_disjoint_field_borrowing.with` |
| 25.6 | `spec_ss05_ephemeral_types.with` |
| 25.7 | `spec_ss07_with_blocks.with` |
| 25.8 | `spec_ss06_handles_and_slotmap.with` |
| 25.9 | `spec_ss10_error_handling.with` |
| 25.10 | `spec_ss11_traits_and_coherence.with` |
| 25.11 | `spec_ss16_ffi_and_c_import.with` |
| 25.12 | `spec_ss09_2_tail_recursion.with` |
| 25.13 | `spec_ss09_4_partial_application.with` |
| 25.14 | `spec_ss09_7_pattern_matching.with` |
| 25.15 | `spec_ss13_3_collection_operations.with` |
| 25.16 | `spec_ss13_4_generators.with` |
| 25.17 | `spec_ss14_async_await.with` |
| 25.18 | `spec_ss14_3_async_calling_is_unrestricted.with` |
| 25.19 | `spec_ss04_2_numerics.with` |
| 25.20 | `spec_ss09_7_exhaustiveness.with` |
| 25.21 | `spec_ss04_3_record_update_syntax.with` |
| 25.22 | `spec_ss10_3_option_result_combinators.with` |
| 25.23 | `spec_ss04_7_ranges.with` |
| 25.24 | `spec_ss09_6_function_composition.with` |
| 25.25 | `spec_ss09_7_parameter_patterns.with` |
| 25.26 | `spec_ss04_4_enum_constructor_imports.with` |
| 25.27 | `spec_ss13_6_comprehensions.with` |
| 25.27b | `spec_ss04_9_implicit_ok_wrapping.with` |
| 25.27c | `spec_ss04_10_implicit_default_return.with` |
| 25.28 | `spec_ss10_5_sequence_traverse_transpose.with` |
| 25.29 | `spec_ss09_6_backward_application.with` |
| 25.30 | `spec_ss20b_denied_patterns.with` |
| 25.31 | `spec_ss02_3_copy_safety.with` |
| 25.32 | `spec_ss14_22_task_ephemerality.with` |
| 25.33 | `spec_ss14_5_postfix_await.with` |
| 25.34 | `spec_ss04_3_field_shorthand.with` |
| 25.35 | `spec_ss04_4_enum_variant_shorthand.with` |
| 25.36 | `spec_ss04_8_tuples.with` |
| 25.37 | `spec_ss10_3_optional_chaining.with` |
| 25.38 | `spec_ss10_4_default_operator.with` |
| 25.39 | `spec_ss09_7_destructuring_let.with` |
| 25.40 | `spec_ss11_8_derive.with` |
| 25.41 | `spec_ss05_5_ephemeral_structs.with` |
| 25.42 | `spec_ss04_3_default_field_values.with` |
| 25.43 | `spec_ss10_6_error_context.with` |
| 25.44 | `spec_ss15_3_string_literals.with` |
| 25.45 | `spec_ss04_8_unit_elision.with` |
| 25.46 | `spec_ss13_5_implicit_iteration.with` |
| 25.46a | `spec_ss13_5a_labeled_break_and_continue.with` |
| 25.47 | `spec_ss18_6_collection_length_methods.with` |
| 25.48 | `spec_ss10_6_unwrap_and_expect.with` |
| 25.49 | `spec_ss18_6_unreachable_todo_assert_matches.with` |
| 25.50 | `spec_ss07_2_builder_block_return.with` |
| 25.51 | `spec_ss14_9_select_await.with` |
| 25.52 | `spec_ss04_4_enum_accessor_methods.with` |
| 25.53 | `spec_ss14_8_scoped_task_tracking.with` |
| 25.54 | `spec_ss09_5_by_value_self_method_chaining.with` |
| 25.55 | `spec_ss03_6_disjoint_closure_captures.with` |
| 25.56 | `spec_ss14_9_select_await_with_let_else_in_branches.with` |
| 25.57 | `spec_ss18_2_drop_in_prelude.with` |
| 25.58 | `spec_ss14_13_await_inside_iterators.with` |
| 25.59 | `spec_ss14_6_async_blocks.with` |
| 25.60 | `spec_ss09_7_reference_pattern_ergonomics.with` |
| 25.61 | `spec_ss02_4_by_value_drop.with` |
| 25.62 | `spec_ss14_7_ephemeral_task_cancellation.with` |
| 25.63 | `spec_ss14_16_scopedsend.with` |
| 25.64 | `spec_ss02_4_partial_move_from_drop_types.with` |
| 25.65 | `spec_ss13_4_generator_views.with` |
| 25.66 | `spec_ss20b_6_comptime_unreachable_exemption.with` |
| 25.67 | `spec_ss14_3_may_suspend_analysis.with` |
| 25.68 | `spec_ss14_19_ffi_callback_no_suspend.with` |
| 25.69 | `spec_ss07_5_with_type_based_dispatch.with` |
| 25.70 | `spec_ss13_2_iter_one_implementation_rule.with` |
| 25.71 | `spec_ss11_7_operator_one_impl_rule.with` |
| 25.72 | `spec_ss14_10_fair_select_await.with` |
| 25.73 | `spec_ss02_4_defer_control_flow_restriction.with` |
| 25.74 | `spec_ss14_7_spawn_fire_and_forget.with` |
| 25.75 | `spec_ss13_2_iterator_borrowing.with` |
| 25.76 | `spec_ss14_15_channel_send_requires_send.with` |
| 25.77 | `spec_ss14_22_ephemeral_owned_passing_restriction.with` |
| 25.78 | `spec_ss03_4_disjoint_slice_operations.with` |
| 25.79 | `spec_ss10_3_optional_chaining_type_aware_desugaring.with` |
| 25.80 | `spec_ss02_4_drop_field_moves.with` |
| 25.81 | `spec_ss13_2_hashmap_lookup_borrowing.with` |
| 25.82 | `spec_ss07_9_nll_based_no_await_guard.with` |
| 25.83 | `spec_ss11_3_object_safety.with` |
| 25.84 | `spec_ss15_3_c_string_literals.with` |
| 25.85 | `spec_ss04_3_record_update_drops_overwritten_fields.with` |
| 25.86 | `spec_ss14_7_ephemeral_task_os_thread_restriction.with` |
| 25.87 | `spec_ss15_3_string_literal_default_type.with` |
| 25.88 | `spec_ss16_1_ffi_direct_call.with` |
| 25.89 | `spec_ss07_1_with_type_based_guard_inference.with` |
| 25.90 | `spec_ss03_7_auto_dereferencing.with` |
| 25.91 | `spec_ss03_8_auto_referencing.with` |
| 25.92 | `spec_ss03_9_implicit_trait_object_coercion.with` |
| 25.93 | `spec_ss04_4_enum_auto_generated_ref_and_mut.with` |
| 25.94 | `spec_ss09_7_chained_if_let.with` |
| 25.95 | `spec_ss17_4_comptime_cascade.with` |
| 25.96 | `spec_ss11_8_derive_builder.with` |
| 25.97 | `spec_ss16_1_raw_pointer_as_option.with` |
| 25.98 | `spec_ss13_3_hashmap_convenience_methods.with` |
| 25.99 | `spec_ss18_7_freestanding_mode.with` |
| 25.100 | `spec_ss09_9_the_in_operator.with` |
| 25.101 | `spec_ss09_1a_named_arguments_and_implicit_context.with` |
| 25.102 | `spec_ss04_2_7_chained_comparisons.with` |
| 25.103 | `spec_ss13_6a_option_and_result_for_comprehensions.with` |
| 25.104 | `spec_ss11_7_multi_index_and_dispatch.with` |
| 25.105 | `spec_ss04_7_range_values.with` |
