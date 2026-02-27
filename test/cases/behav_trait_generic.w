//! expect-stdout: ok

// Behavior test: trait-bounded generics (Rust ui/traits/, ui/generics/)
// Tests: generic type params with trait bounds, solver resolution for
// bounded generics, obligation collection and fulfillment

use Type
use Traits

fn test_trait_with_method:
    var solver = TraitSolver.new()
    // Define trait Add with method "add(self, other) -> Self"
    var method_names = Vec.new()
    method_names.push(1)  // "add"
    var method_params = Vec.new()
    method_params.push(2)  // self + other
    var method_rets = Vec.new()
    method_rets.push(TYPE_I32())  // returns i32
    TraitSolver.add_trait(solver, 100, method_names, method_params, method_rets)
    let idx = TraitSolver.find_trait(solver, 100)
    assert(idx >= 0)
    let def = TraitSolver.get_trait(solver, idx)
    assert(def.method_count == 1)

fn test_impl_satisfies_bound:
    var solver = TraitSolver.new()
    // Define trait Display
    var mn = Vec.new()
    mn.push(1)  // "display"
    var mp = Vec.new()
    mp.push(1)  // self
    var mr = Vec.new()
    mr.push(TYPE_STR())
    TraitSolver.add_trait(solver, 200, mn, mp, mr)
    // Impl: i32 implements Display
    var impl_methods = Vec.new()
    impl_methods.push(1)  // "display"
    TraitSolver.add_impl(solver, TYPE_I32(), 200, impl_methods)
    // Resolve: does i32 implement Display?
    assert(TraitSolver.implements(solver, 200, TYPE_I32()) == true)
    // f64 does NOT implement Display
    assert(TraitSolver.implements(solver, 200, TYPE_F64()) == false)

fn test_generic_bound_obligation:
    // Simulate: fn print_it[T: Display](x: T)
    // When called with print_it(42), T=i32, must check i32: Display
    var solver = TraitSolver.new()
    // Define Display trait
    var mn = Vec.new()
    mn.push(1)
    var mp = Vec.new()
    mp.push(1)
    var mr = Vec.new()
    mr.push(TYPE_STR())
    TraitSolver.add_trait(solver, 300, mn, mp, mr)
    // Impl: i32 implements Display
    var im = Vec.new()
    im.push(1)
    TraitSolver.add_impl(solver, TYPE_I32(), 300, im)
    // Create obligation for T=i32 with bound Display
    var obligations = ObligationList.new()
    let ob = TraitObligation.new(300, TYPE_I32(), 0, 0)
    ObligationList.add(obligations, ob)
    let result = ObligationList.resolve_all(obligations, solver)
    assert(result == TR_OK())

fn test_generic_bound_fails:
    // fn sort[T: Ord](items: Vec[T]) — calling with str where str !: Ord
    var solver = TraitSolver.new()
    // Define Ord trait
    var mn = Vec.new()
    mn.push(1)
    var mp = Vec.new()
    mp.push(2)
    var mr = Vec.new()
    mr.push(TYPE_BOOL())
    TraitSolver.add_trait(solver, 400, mn, mp, mr)
    // No impl for str!
    var obligations = ObligationList.new()
    let ob = TraitObligation.new(400, TYPE_STR(), 0, 0)
    ObligationList.add(obligations, ob)
    let result = ObligationList.resolve_all(obligations, solver)
    assert(result < 0)  // Should fail

fn test_multiple_trait_bounds:
    // fn f[T: Display + Clone](x: T) — T must satisfy both bounds
    var solver = TraitSolver.new()
    // Define Display
    var mn1 = Vec.new()
    mn1.push(1)
    var mp1 = Vec.new()
    mp1.push(1)
    var mr1 = Vec.new()
    mr1.push(TYPE_STR())
    TraitSolver.add_trait(solver, 500, mn1, mp1, mr1)
    // Define Clone
    var mn2 = Vec.new()
    mn2.push(2)
    var mp2 = Vec.new()
    mp2.push(1)
    var mr2 = Vec.new()
    mr2.push(TYPE_I32())
    TraitSolver.add_trait(solver, 501, mn2, mp2, mr2)
    // i32 implements both
    var im1 = Vec.new()
    im1.push(1)
    TraitSolver.add_impl(solver, TYPE_I32(), 500, im1)
    var im2 = Vec.new()
    im2.push(2)
    TraitSolver.add_impl(solver, TYPE_I32(), 501, im2)
    // Check both obligations
    var obligations = ObligationList.new()
    ObligationList.add(obligations, TraitObligation.new(500, TYPE_I32(), 0, 0))
    ObligationList.add(obligations, TraitObligation.new(501, TYPE_I32(), 0, 0))
    assert(ObligationList.resolve_all(obligations, solver) == TR_OK())

fn test_partial_bound_satisfaction:
    // T satisfies Display but NOT Clone → should fail
    var solver = TraitSolver.new()
    var mn1 = Vec.new()
    mn1.push(1)
    var mp1 = Vec.new()
    mp1.push(1)
    var mr1 = Vec.new()
    mr1.push(TYPE_STR())
    TraitSolver.add_trait(solver, 600, mn1, mp1, mr1)
    var mn2 = Vec.new()
    mn2.push(2)
    var mp2 = Vec.new()
    mp2.push(1)
    var mr2 = Vec.new()
    mr2.push(TYPE_I32())
    TraitSolver.add_trait(solver, 601, mn2, mp2, mr2)
    // i32 only implements Display (600), NOT Clone (601)
    var im = Vec.new()
    im.push(1)
    TraitSolver.add_impl(solver, TYPE_I32(), 600, im)
    var obligations = ObligationList.new()
    ObligationList.add(obligations, TraitObligation.new(600, TYPE_I32(), 0, 0))
    ObligationList.add(obligations, TraitObligation.new(601, TYPE_I32(), 0, 0))
    let result = ObligationList.resolve_all(obligations, solver)
    assert(result < 0)  // Fails on Clone

fn test_trait_method_query:
    var solver = TraitSolver.new()
    var mn = Vec.new()
    mn.push(10)  // "add"
    mn.push(20)  // "sub"
    var mp = Vec.new()
    mp.push(2)
    mp.push(2)
    var mr = Vec.new()
    mr.push(TYPE_I32())
    mr.push(TYPE_I32())
    TraitSolver.add_trait(solver, 700, mn, mp, mr)
    let idx = TraitSolver.find_trait(solver, 700)
    assert(idx >= 0)
    assert(TraitSolver.trait_method_name(solver, idx, 0) == 10)
    assert(TraitSolver.trait_method_name(solver, idx, 1) == 20)
    assert(TraitSolver.trait_method_param_count(solver, idx, 0) == 2)
    assert(TraitSolver.trait_method_ret_type(solver, idx, 0) == TYPE_I32())

fn test_coherence_no_overlap:
    var solver = TraitSolver.new()
    var mn = Vec.new()
    mn.push(1)
    var mp = Vec.new()
    mp.push(1)
    var mr = Vec.new()
    mr.push(TYPE_I32())
    TraitSolver.add_trait(solver, 800, mn, mp, mr)
    // Different types implement same trait → coherent
    var im1 = Vec.new()
    im1.push(1)
    TraitSolver.add_impl(solver, TYPE_I32(), 800, im1)
    var im2 = Vec.new()
    im2.push(1)
    TraitSolver.add_impl(solver, TYPE_F64(), 800, im2)
    assert(TraitSolver.check_coherence(solver) == true)

fn test_coherence_overlap_detected:
    var solver = TraitSolver.new()
    var mn = Vec.new()
    mn.push(1)
    var mp = Vec.new()
    mp.push(1)
    var mr = Vec.new()
    mr.push(TYPE_I32())
    TraitSolver.add_trait(solver, 900, mn, mp, mr)
    // Same type implements same trait TWICE → incoherent
    var im1 = Vec.new()
    im1.push(1)
    TraitSolver.add_impl(solver, TYPE_I32(), 900, im1)
    var im2 = Vec.new()
    im2.push(1)
    TraitSolver.add_impl(solver, TYPE_I32(), 900, im2)
    assert(TraitSolver.check_coherence(solver) == false)

fn main:
    test_trait_with_method()
    test_impl_satisfies_bound()
    test_generic_bound_obligation()
    test_generic_bound_fails()
    test_multiple_trait_bounds()
    test_partial_bound_satisfaction()
    test_trait_method_query()
    test_coherence_no_overlap()
    test_coherence_overlap_detected()
    println("ok")
