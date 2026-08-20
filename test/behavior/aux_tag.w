//! check-only

// Companion module for behav_local_callable_precedence.w. test/behavior/*.w is
// a flat test glob, so a support module has to be a valid test too; check-only
// is the spelling for one that has no main of its own.
pub fn tag() -> i32: 100
