//! expect-stdout: ok

use Type
use Traits

fn test_trait_def:
    var solver = TraitSolver.new()
    var mnames = Vec.new()
    mnames.push(10)
    mnames.push(11)
    var mparams = Vec.new()
    mparams.push(1)
    mparams.push(0)
    var mrets = Vec.new()
    mrets.push(TYPE_STR())
    mrets.push(TYPE_VOID())
    TraitSolver.add_trait(solver, 100, mnames, mparams, mrets)
    assert(TraitSolver.find_trait(solver, 100) == 0)
    assert(TraitSolver.find_trait(solver, 999) == -1)
    let def = TraitSolver.get_trait(solver, 0)
    assert(def.name == 100)
    assert(def.method_count == 2)
    assert(TraitSolver.trait_method_name(solver, 0, 0) == 10)
    assert(TraitSolver.trait_method_name(solver, 0, 1) == 11)
    assert(TraitSolver.trait_method_param_count(solver, 0, 0) == 1)
    assert(TraitSolver.trait_method_ret_type(solver, 0, 0) == TYPE_STR())

fn test_impl_and_resolve:
    var solver = TraitSolver.new()
    // Define trait "Display" with one method
    var mnames = Vec.new()
    mnames.push(10)
    var mparams = Vec.new()
    mparams.push(1)
    var mrets = Vec.new()
    mrets.push(TYPE_STR())
    TraitSolver.add_trait(solver, 100, mnames, mparams, mrets)

    // Impl: type 50 implements trait 100
    var impl_methods = Vec.new()
    impl_methods.push(10)
    TraitSolver.add_impl(solver, 50, 100, impl_methods)

    // Should resolve
    assert(TraitSolver.implements(solver, 100, 50))
    // Should not resolve for type 51
    assert(not TraitSolver.implements(solver, 100, 51))
    // Should cache the result
    let r1 = TraitSolver.resolve(solver, 100, 50)
    let r2 = TraitSolver.resolve(solver, 100, 50)
    assert(r1 == r2)
    assert(r1 >= 0)

fn test_no_trait:
    var solver = TraitSolver.new()
    let r = TraitSolver.resolve(solver, 999, 50)
    assert(r < 0)

fn test_coherence:
    var solver = TraitSolver.new()
    var mnames = Vec.new()
    mnames.push(10)
    var mparams = Vec.new()
    mparams.push(1)
    var mrets = Vec.new()
    mrets.push(TYPE_STR())
    TraitSolver.add_trait(solver, 100, mnames, mparams, mrets)

    // Single impl — coherent
    var impl1 = Vec.new()
    impl1.push(10)
    TraitSolver.add_impl(solver, 50, 100, impl1)
    assert(TraitSolver.check_coherence(solver))

    // Different type — still coherent
    var impl2 = Vec.new()
    impl2.push(10)
    TraitSolver.add_impl(solver, 51, 100, impl2)
    assert(TraitSolver.check_coherence(solver))

    // Same type, same trait — incoherent!
    var impl3 = Vec.new()
    impl3.push(10)
    TraitSolver.add_impl(solver, 50, 100, impl3)
    assert(not TraitSolver.check_coherence(solver))

fn test_obligation_list:
    var solver = TraitSolver.new()
    var mnames = Vec.new()
    mnames.push(10)
    var mparams = Vec.new()
    mparams.push(1)
    var mrets = Vec.new()
    mrets.push(TYPE_STR())
    TraitSolver.add_trait(solver, 100, mnames, mparams, mrets)

    var impl1 = Vec.new()
    impl1.push(10)
    TraitSolver.add_impl(solver, 50, 100, impl1)

    var obligations = ObligationList.new()
    let ob = TraitObligation.new(100, 50, 0, 0)
    ObligationList.add(obligations, ob)
    assert(ObligationList.count(obligations) == 1)
    assert(ObligationList.resolve_all(obligations, solver) == TR_OK())

    // Add unresolvable obligation
    let ob2 = TraitObligation.new(100, 99, 0, 0)
    ObligationList.add(obligations, ob2)
    assert(ObligationList.resolve_all(obligations, solver) < 0)

fn main:
    test_trait_def()
    test_impl_and_resolve()
    test_no_trait()
    test_coherence()
    test_obligation_list()
    println("ok")
