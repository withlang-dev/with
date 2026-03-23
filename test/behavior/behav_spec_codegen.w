//! check-only

// Spec conformance: lowering/codegen behavior
// TODO: Many features tested here require the spec_harness module
// which is an internal test driver. Individual features are tested
// in their respective end-to-end test files:
// - behav_comptime.w (comptime expressions)
// - behav_record_update.w (record update)
// - behav_match.w (match expressions)
// - behav_pipeline.w (pipeline operator)
// - behav_closure.w (closures)
// - behav_defer.w (defer)

fn main:
    let x = 42
    assert(x == 42)
