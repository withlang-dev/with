//! check-only
// Regression helper for issue #113.
// Keep the owner untyped so sema must merge the extern declaration rather than
// relying on the frontend's current extern-var decl filter.

var issue113_shared_counter = 41
