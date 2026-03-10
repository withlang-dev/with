//! expect-stdout: ok

// Compile error test: trait bound failures
// Tests that the trait solver correctly rejects unimplemented traits

use Types

fn test_unimplemented_trait:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Display", 1)
    // No impl for type 5
    let r = TraitSolver.resolve(solver, "Display", 5)
    assert(r == 0)

fn test_wrong_trait:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Display", 1)
    TraitSolver.add_trait(solver, "Clone", 0)
    TraitSolver.add_impl(solver, "Display", 5)
    // Type 5 has Display but not Clone
    assert(TraitSolver.resolve(solver, "Display", 5) == 1)
    assert(TraitSolver.resolve(solver, "Clone", 5) == 0)

fn test_obligation_fails:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Eq", 0)
    // No impls
    var obs = ObligationList.new()
    ObligationList.add(obs, "Eq", TYPE_I32)
    let ok = ObligationList.resolve_all(obs, solver)
    assert(ok == 0)

fn test_multiple_obligations:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Display", 1)
    TraitSolver.add_trait(solver, "Clone", 0)
    TraitSolver.add_impl(solver, "Display", TYPE_I32)
    TraitSolver.add_impl(solver, "Clone", TYPE_I32)
    var obs = ObligationList.new()
    ObligationList.add(obs, "Display", TYPE_I32)
    ObligationList.add(obs, "Clone", TYPE_I32)
    assert(ObligationList.count(obs) == 2)
    let ok = ObligationList.resolve_all(obs, solver)
    assert(ok == 1)

fn test_partial_obligations:
    var solver = TraitSolver.new()
    TraitSolver.add_trait(solver, "Display", 1)
    TraitSolver.add_trait(solver, "Clone", 0)
    TraitSolver.add_impl(solver, "Display", TYPE_I32)
    // Clone NOT implemented for i32
    var obs = ObligationList.new()
    ObligationList.add(obs, "Display", TYPE_I32)
    ObligationList.add(obs, "Clone", TYPE_I32)
    let ok = ObligationList.resolve_all(obs, solver)
    assert(ok == 0)  // should fail because Clone missing

fn main:
    test_unimplemented_trait()
    test_wrong_trait()
    test_obligation_fails()
    test_multiple_obligations()
    test_partial_obligations()
    println("ok")
