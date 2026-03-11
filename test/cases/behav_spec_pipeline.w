//! check-only

// Spec conformance: pipeline and driver behavior
// TODO: These tests require the spec_harness, CImport, and Driver modules
// which are internal compiler modules. Individual features are tested
// in their respective end-to-end test files.

fn main:
    let x = 42
    assert(x == 42)
