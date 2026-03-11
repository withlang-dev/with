//! check-only

// Spec conformance: semantics/type-system behavior
// TODO: These tests require the spec_harness module which is an
// internal test driver. Individual semantic features are tested
// in their respective end-to-end test files:
// - behav_struct.w (struct construction/methods)
// - behav_trait.w (trait impl/dispatch)
// - behav_generic.w (generic types)
// - behav_for.w (for loop bindings)
// - behav_match.w (match expressions)

fn main:
    let x = 42
    assert(x == 42)
