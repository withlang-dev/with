//! check-only
// Regression helper for issue #113.
// The owner is untyped; issue2335_extern_var_typed_owner.w is the typed case.
// Sema merges the extern declaration with its owner either way.

var issue113_shared_counter = 41
